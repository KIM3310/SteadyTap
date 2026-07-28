# Search Growth Implementation - SteadyTap

This repository now exposes a search-readable service surface in addition to the system architecture. The implementation is designed to support organic discovery, AI answer surfaces, and a free-to-paid service path without committing to paid infrastructure first.

## Implemented Surface

| Surface | Path |
| --- | --- |
| Machine-readable offer | [docs/service-offer.json](./service-offer.json) |
| Revenue architecture | [docs/revenue-architecture.md](./revenue-architecture.md) |
| System architecture | [docs/system-architecture.md](./system-architecture.md) |
| Public canonical URL | https://steadytap.pages.dev/ |
| Lead capture URL | https://kim3310-doeon-kim-portfolio.pages.dev/?offer=SteadyTap&inquiry=consumer-prototype-customization#private-inquiry |
| Repository resource route | https://kim3310-doeon-kim-portfolio.pages.dev/resources/SteadyTap/ |
| Commercial route | https://kim3310-doeon-kim-portfolio.pages.dev/?offer=SteadyTap#service-offers |

## Search Positioning

- Primary query: SteadyTap calibration adaptive touch
- Secondary queries: SteadyTap demo; SteadyTap system architecture; touch calibration app; adaptive touch challenge toolkit with coach handoff support
- Public entry point: free local-first mobile demo and static explainer
- Paid boundary: fixed-scope private prototype customization for one audience-specific workflow

## Conversion Boundary

The public surface stays crawlable and free. Paid value starts when a visitor wants an audience-specific flow, branded content, privacy and claim boundaries, deployment packaging, or implementation support.

## Deployment Notes

- Keep the sitemap and robots file aligned with the final production domain.
- Submit the canonical URL and sitemap in Google Search Console after the domain is connected.
- The lead-capture path is the central private inquiry route with `inquiry=consumer-prototype-customization`; no checkout provider is configured in this repository.
- Keep exact free-tier quotas out of public promises because provider limits change.
