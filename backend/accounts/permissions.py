from rest_framework.permissions import BasePermission


class IsFarmer(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_farmer)


class IsVet(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_vet)


class IsAuthority(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_authority)


class IsSystemAdmin(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_system_admin)


class IsFarmerOrVet(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and
                    (request.user.is_farmer or request.user.is_vet))


class IsOwnerOrAdmin(BasePermission):
    """Object-level permission: only the owner or an admin can access."""
    def has_object_permission(self, request, view, obj):
        if request.user.is_system_admin:
            return True
        owner = getattr(obj, 'owner', None) or getattr(obj, 'user', None) or getattr(obj, 'created_by', None)
        return owner == request.user
