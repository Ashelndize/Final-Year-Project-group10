"""
Django config package.

If mysqlclient is unavailable on this platform, PyMySQL is used as a
drop-in replacement. The install_as_MySQLdb() call must happen before
Django's database layer is loaded (i.e. here in __init__.py).
"""
try:
    import MySQLdb  # noqa: F401 — mysqlclient is available, nothing to do
except ImportError:
    # Fallback to PyMySQL (pure-Python MySQL driver)
    try:
        import pymysql
        pymysql.install_as_MySQLdb()
    except ImportError:
        pass  # Neither driver available — will raise a clear error at startup
