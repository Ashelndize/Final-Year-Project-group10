from rest_framework import viewsets, filters
from rest_framework.permissions import IsAuthenticated
from .models import Animal
from .serializers import AnimalSerializer


class AnimalViewSet(viewsets.ModelViewSet):
    serializer_class = AnimalSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['tag_number', 'name', 'species', 'breed']
    ordering_fields = ['tag_number', 'species', 'created_at']

    def get_queryset(self):
        user = self.request.user
        if user.is_system_admin:
            return Animal.objects.all().select_related('farm', 'farm__owner')
        return Animal.objects.filter(farm__owner=user).select_related('farm', 'farm__owner')
