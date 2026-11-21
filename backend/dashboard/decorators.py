from functools import wraps
from django.shortcuts import redirect


def authority_required(view_func):
    """Restricts view to authenticated AUTHORITY or ADMIN users."""
    @wraps(view_func)
    def _wrapper(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return redirect('dashboard:login')
        if request.user.role not in ('AUTHORITY', 'ADMIN'):
            return redirect('dashboard:login')
        return view_func(request, *args, **kwargs)
    return _wrapper
