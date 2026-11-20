from django.contrib import admin
from .models import Area, Farm


@admin.register(Area)
class AreaAdmin(admin.ModelAdmin):
    list_display = ('name', 'province', 'country')
    search_fields = ('name', 'province')


@admin.register(Farm)
class FarmAdmin(admin.ModelAdmin):
    list_display = ('name', 'owner', 'farm_type', 'area', 'status', 'created_at')
    list_filter = ('farm_type', 'status')
    search_fields = ('name', 'owner__username')
