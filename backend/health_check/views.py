"""
Health-check endpoint.

Provides a single unauthenticated GET endpoint that returns a JSON
status object. Used to verify that the backend is running and
reachable from other services (e.g. the Flutter mobile app).

Endpoint: GET /api/v1/health/
Response: {"status": "ok", "service": "livestock-backend"}
"""

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response


@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """
    Return a simple JSON object confirming the backend is reachable.

    This endpoint requires no authentication. It is intended for:
    - Flutter app connectivity checks on first launch.
    - Load-balancer / container health probes in production.
    - CI/CD smoke tests after deployment.
    """
    return Response({
        'status': 'ok',
        'service': 'livestock-backend',
    })
