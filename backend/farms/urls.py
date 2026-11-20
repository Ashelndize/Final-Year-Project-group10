from rest_framework.routers import DefaultRouter
from .views import AreaViewSet, FarmViewSet

router = DefaultRouter()
router.register(r'areas', AreaViewSet, basename='area')
router.register(r'farms', FarmViewSet, basename='farm')

urlpatterns = router.urls
