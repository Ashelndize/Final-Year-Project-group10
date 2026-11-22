# =============================================================================
# gunicorn.conf.py — Smart Livestock Health and Farm Management System
# =============================================================================
# Used when starting the backend in production:
#   gunicorn -c gunicorn.conf.py config.wsgi:application
# =============================================================================

import multiprocessing

# ---------------------------------------------------------------------------
# Server socket
# ---------------------------------------------------------------------------
bind = "0.0.0.0:8000"
backlog = 2048

# ---------------------------------------------------------------------------
# Workers
# ---------------------------------------------------------------------------
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
timeout = 120
keepalive = 5

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
accesslog = "-"      # stdout — captured by the process manager / syslog
errorlog = "-"       # stderr
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"'

# ---------------------------------------------------------------------------
# Process naming
# ---------------------------------------------------------------------------
proc_name = "livestock_api"

# ---------------------------------------------------------------------------
# Server mechanics
# ---------------------------------------------------------------------------
daemon = False          # process manager (systemd / Heroku) handles this
preload_app = True      # load app before forking — saves memory via copy-on-write
max_requests = 1000     # recycle workers after N requests (guards memory leaks)
max_requests_jitter = 50
