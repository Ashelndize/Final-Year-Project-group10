from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AssistantAskView, KBSourceViewSet

router = DefaultRouter()
router.register('kb-sources', KBSourceViewSet, basename='kb-source')

urlpatterns = [
    path('assistant/ask/', AssistantAskView.as_view(), name='assistant-ask'),
    path('', include(router.urls)),
]
