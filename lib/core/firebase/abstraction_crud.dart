import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:service_delivery/core/firebase/dto/abstract_dto.dart';

abstract class AbstractionCrud<D extends AbstractDto> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future create(D dto) async {
    await _firestore.collection(collectionName()).add(dto.toJson());
  }

  Future delete(String id) async {
    await _firestore.collection(collectionName()).doc(id).delete();
  }

  Future update(String id, D dto) async {
    await _firestore.collection(collectionName()).doc(id).update(dto.toJson());
  }

  Future<D> getOne(String id) async {
    final response =
        await _firestore.collection(collectionName()).doc(id).get();
    final D dto = toSummaryDto(response.data()) as D;
    return dto;
  }

  Future<List<D>> searchAll({Map<dynamic, String>? query}) async {
    final response = await _firestore
        .collection(collectionName())
        .where(D.toString(), isEqualTo: query)
        .get();
    return response.docs.map((snapshot) {
      final D dto = toSummaryDto(snapshot.data()) as D;
      return dto;
    }).toList();
  }

  D? toSummaryDto(dynamic json);

  String collectionName();
}
