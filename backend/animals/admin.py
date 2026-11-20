from django.contrib import admin
from .models import Animal


@admin.register(Animal)
class AnimalAdmin(admin.ModelAdmin):
    list_display = ('tag_number', 'name', 'species', 'farm', 'status', 'created_at')
    list_filter = ('species', 'status', 'sex')
    search_fields = ('tag_number', 'name', 'farm__name')
