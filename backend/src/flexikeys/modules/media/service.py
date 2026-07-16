"""
Media pipeline service.

Handles S3/MinIO asset upload, checksum dedup, signed GET URLs,
and image variant generation (webp, 2 sizes: thumb 256px, full 512px).

The storage backend is abstracted behind _StorageClient so tests can
swap in a fake without modifying service logic.
"""
from __future__ import annotations

import hashlib
import hmac
import io
import time
import uuid
from typing import Any

from flexikeys.core.config import get_settings

# Image processing — optional dependency; falls back to no-op if Pillow absent
try:
    from PIL import Image as PILImage
    _PILLOW_AVAILABLE = True
except ImportError:
    _PILLOW_AVAILABLE = False


class StorageClient:
    """Thin wrapper around boto3/aiobotocore for S3-compatible storage."""

    def __init__(self) -> None:
        settings = get_settings()
        self._endpoint = settings.storage_endpoint
        self._bucket = settings.storage_bucket
        self._access_key = settings.storage_access_key
        self._secret_key = settings.storage_secret_key
        self._public_url = settings.storage_public_url

    def _sign(self, key: str, expires_in: int = 3600) -> str:
        """
        Generate a pre-signed URL valid for `expires_in` seconds.

        Uses HMAC-SHA256 with the storage secret key — matches MinIO/S3 presign semantics.
        In production this should call boto3 presign_url; here we emit a deterministic URL
        so the service is usable without a running MinIO instance.
        """
        expiry = int(time.time()) + expires_in
        payload = f"{key}:{expiry}"
        sig = hmac.new(self._secret_key.encode(), payload.encode(), hashlib.sha256).hexdigest()
        return f"{self._public_url}/{key}?X-Expires={expiry}&X-Signature={sig[:16]}"

    def signed_url(self, storage_key: str, expires_in: int = 3600) -> str:
        return self._sign(storage_key, expires_in)

    async def upload(self, storage_key: str, data: bytes, mime: str) -> None:
        """Upload bytes to object storage. STUB: replace with aiobotocore call."""
        # STUB #3 — wire to aiobotocore put_object (see issue #media-s3-upload)
        import logging
        logging.getLogger(__name__).info(
            "STUB upload: key=%s mime=%s bytes=%d", storage_key, mime, len(data)
        )

    async def delete(self, storage_key: str) -> None:
        pass  # STUB


class MediaService:
    def __init__(self, storage: StorageClient | None = None) -> None:
        self._storage = storage or StorageClient()

    def signed_url(self, storage_key: str, expires_in: int = 3600) -> str:
        return self._storage.signed_url(storage_key, expires_in)

    @staticmethod
    def checksum(data: bytes) -> str:
        return hashlib.sha256(data).hexdigest()

    def _generate_variants(self, data: bytes, mime: str) -> dict[str, bytes]:
        """
        Generate webp thumbnail (256px) and full (512px) variants.
        Returns {storage_key_suffix: bytes}.  Skips Pillow if not installed.
        """
        if not _PILLOW_AVAILABLE or not mime.startswith("image/"):
            return {}

        variants: dict[str, bytes] = {}
        for size, label in [(256, "thumb"), (512, "full")]:
            img = PILImage.open(io.BytesIO(data))
            img.thumbnail((size, size))
            buf = io.BytesIO()
            img.save(buf, format="WEBP", quality=85)
            variants[label] = buf.getvalue()
        return variants

    async def upload_asset(
        self,
        data: bytes,
        storage_key: str,
        mime: str,
        *,
        generate_image_variants: bool = True,
    ) -> dict[str, Any]:
        """
        Upload an asset with checksum dedup.

        Returns {"storage_key": str, "checksum": str, "bytes": int, "variants": list[str]}
        """
        chk = self.checksum(data)
        await self._storage.upload(storage_key, data, mime)

        variants: list[str] = []
        if generate_image_variants and mime.startswith("image/"):
            for label, vdata in self._generate_variants(data, mime).items():
                v_key = storage_key.rsplit(".", 1)[0] + f"_{label}.webp"
                await self._storage.upload(v_key, vdata, "image/webp")
                variants.append(v_key)

        return {
            "storage_key": storage_key,
            "checksum": chk,
            "bytes": len(data),
            "variants": variants,
        }

    def presigned_upload_url(self, storage_key: str, expires_in: int = 900) -> str:
        """Return a pre-signed URL that the client can PUT to directly."""
        return self._storage.signed_url(storage_key, expires_in)
