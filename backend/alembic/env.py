from __future__ import annotations

import asyncio
import os
import sys
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from flexikeys.core.config import get_settings  # noqa: E402
from flexikeys.core.db import Base  # noqa: E402

# Import every model module so Alembic's autogenerate sees all tables
import flexikeys.modules.users.models  # noqa: F401, E402
import flexikeys.modules.auth.models  # noqa: F401, E402
import flexikeys.modules.children.models  # noqa: F401, E402
import flexikeys.modules.curriculum.models  # noqa: F401, E402
import flexikeys.modules.sessions.models  # noqa: F401, E402
import flexikeys.modules.adaptive.models  # noqa: F401, E402
import flexikeys.modules.progress.models  # noqa: F401, E402
import flexikeys.modules.rewards.models  # noqa: F401, E402
import flexikeys.modules.teacher.models  # noqa: F401, E402
import flexikeys.modules.ai_assistant.models  # noqa: F401, E402
import flexikeys.modules.notifications.models  # noqa: F401, E402
import flexikeys.modules.parent.models  # noqa: F401, E402

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

settings = get_settings()
config.set_main_option("sqlalchemy.url", settings.database_url)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


def run_migrations_online() -> None:
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
