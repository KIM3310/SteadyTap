from __future__ import annotations

import importlib.util
import io
import json
import tempfile
import unittest
from contextlib import redirect_stderr
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
VALIDATOR_PATH = ROOT / "scripts" / "validate_repository_surface.py"

spec = importlib.util.spec_from_file_location("validate_repository_surface", VALIDATOR_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError(f"unable to load validator from {VALIDATOR_PATH}")
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class ServiceOfferValidationTests(unittest.TestCase):
    def test_mismatch_does_not_echo_manifest_value(self) -> None:
        service_offer = json.loads(
            (ROOT / "docs" / "service-offer.json").read_text(encoding="utf-8")
        )
        sensitive_value = "private-billing-reference-for-regression-test"
        service_offer["commerce"]["billing_mode"] = sensitive_value

        with tempfile.TemporaryDirectory() as temp_dir:
            docs_offer = Path(temp_dir) / "docs-service-offer.json"
            site_offer = Path(temp_dir) / "site-service-offer.json"
            serialized_offer = json.dumps(service_offer)
            docs_offer.write_text(serialized_offer, encoding="utf-8")
            site_offer.write_text(serialized_offer, encoding="utf-8")
            stderr = io.StringIO()

            with (
                patch.object(validator, "DOCS_SERVICE_OFFER", docs_offer),
                patch.object(validator, "SITE_SERVICE_OFFER", site_offer),
                redirect_stderr(stderr),
                self.assertRaises(SystemExit) as raised,
            ):
                validator.check_service_offer_surface()

        self.assertEqual(raised.exception.code, 1)
        self.assertEqual(
            stderr.getvalue(),
            "repository surface validation failed: commerce.billing_mode mismatch\n",
        )
        self.assertNotIn(sensitive_value, stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
