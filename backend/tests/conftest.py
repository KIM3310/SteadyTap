from contextlib import AsyncExitStack

import pytest
from httpx2 import ASGITransport, AsyncClient


@pytest.fixture
def anyio_backend():
    return "asyncio"


@pytest.fixture
async def client_factory():
    """Exercise the ASGI application directly and close every client after the test."""
    async with AsyncExitStack() as stack:
        async def create(app):
            return await stack.enter_async_context(
                AsyncClient(transport=ASGITransport(app=app), base_url="http://testserver")
            )

        yield create
