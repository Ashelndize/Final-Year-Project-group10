from django.urls import path
from . import views

app_name = 'dashboard'

urlpatterns = [
    path('', views.home, name='home'),
    path('login/', views.dashboard_login, name='login'),
    path('logout/', views.dashboard_logout, name='logout'),

    # Disease reports
    path('reports/', views.reports_list, name='reports_list'),
    path('reports/<int:pk>/', views.report_detail, name='report_detail'),
    path('reports/<int:pk>/review/', views.report_review, name='report_review'),
    path('reports/<int:pk>/confirm-outbreak/', views.report_confirm_outbreak, name='report_confirm_outbreak'),

    # Announcements
    path('announcements/', views.announcements_list, name='announcements_list'),
    path('announcements/new/', views.announcement_create, name='announcement_create'),
    path('announcements/<int:pk>/', views.announcement_detail, name='announcement_detail'),
    path('announcements/<int:pk>/publish/', views.announcement_publish, name='announcement_publish'),
    path('announcements/<int:pk>/withdraw/', views.announcement_withdraw, name='announcement_withdraw'),
]
