from django.urls import path
from . import views

app_name = 'dashboard'

urlpatterns = [
    path('', views.dashboard_index, name='index'),
    path('login/', views.dashboard_login, name='login'),
    path('logout/', views.dashboard_logout, name='logout'),
    path('reports/', views.report_queue, name='report_queue'),
    path('reports/<int:report_id>/', views.report_detail, name='report_detail'),
    path('announcements/', views.announcement_list, name='announcement_list'),
    path('announcements/new/', views.announcement_create, name='announcement_create'),
    path('announcements/<int:ann_id>/', views.announcement_detail, name='announcement_detail'),
    path('announcements/<int:ann_id>/edit/', views.announcement_edit, name='announcement_edit'),
    path('announcements/<int:ann_id>/publish/', views.announcement_publish, name='announcement_publish'),
    path('announcements/<int:ann_id>/withdraw/', views.announcement_withdraw, name='announcement_withdraw'),
]
