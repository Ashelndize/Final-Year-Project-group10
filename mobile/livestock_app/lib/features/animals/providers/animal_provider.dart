import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/animal.dart';

class AnimalProvider extends ChangeNotifier {
  List<Animal> _animals = [];
  bool _loading = false;
  String? _error;

  List<Animal> get animals => _animals;
  bool get loading => _loading;
  String? get error => _error;

  List<Animal> animalsForFarm(int farmId) =>
      _animals.where((a) => a.farmId == farmId).toList();

  Future<void> loadAnimals({int? farmId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final params = farmId != null ? {'farm': farmId.toString()} : null;
      final data = await ApiClient.getList(
        ApiEndpoints.animals,
        queryParams: params,
      );
      final results = data['results'] as List<dynamic>? ?? [];
      _animals = results
          .map((e) => Animal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load animals.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> createAnimal({
    required int farmId,
    required String tagNumber,
    required String species,
    required String sex,
    String name = '',
    String breed = '',
    String? dateOfBirth,
    String? weightKg,
    String notes = '',
  }) async {
    try {
      final body = <String, dynamic>{
        'farm': farmId,
        'tag_number': tagNumber,
        'species': species,
        'sex': sex,
        'name': name,
        'breed': breed,
        'notes': notes,
      };
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        body['date_of_birth'] = dateOfBirth;
      }
      if (weightKg != null && weightKg.isNotEmpty) {
        body['weight_kg'] = weightKg;
      }
      final data = await ApiClient.post(ApiEndpoints.animals, body);
      _animals.insert(0, Animal.fromJson(data));
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to register animal.';
      notifyListeners();
      return false;
    }
  }

  Animal? getById(int id) {
    try {
      return _animals.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
