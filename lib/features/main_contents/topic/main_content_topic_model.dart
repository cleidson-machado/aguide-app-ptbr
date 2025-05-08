// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class MainContentTopicModel {
  
  final String id;
  final String title;
  final String subTitle;
  final String description;
  final String contentImageUrl;
  final String bioAnnotationInfo;

  MainContentTopicModel({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.description,
    required this.contentImageUrl,
    required this.bioAnnotationInfo,
  });

  MainContentTopicModel copyWith({
    String? id,
    String? title,
    String? subTitle,
    String? description,
    String? contentImageUrl,
    String? bioAnnotationInfo,
  }) {
    return MainContentTopicModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      description: description ?? this.description,
      contentImageUrl: contentImageUrl ?? this.contentImageUrl,
      bioAnnotationInfo: bioAnnotationInfo ?? this.bioAnnotationInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subTitle': subTitle,
      'description': description,
      'contentImageUrl': contentImageUrl,
      'bioAnnotationInfo': bioAnnotationInfo,
    };
  }

  factory MainContentTopicModel.fromMap(Map<String, dynamic> map) {
    return MainContentTopicModel(
      id: map['id'] as String,
      title: map['title'] as String,
      subTitle: map['subTitle'] as String,
      description: map['description'] as String,
      contentImageUrl: map['contentImageUrl'] as String,
      bioAnnotationInfo: map['bioAnnotationInfo'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory MainContentTopicModel.fromJson(String source) => MainContentTopicModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MainContentTopicModel(id: $id, title: $title, subTitle: $subTitle, description: $description, contentImageUrl: $contentImageUrl, bioAnnotationInfo: $bioAnnotationInfo)';
  }

  @override
  bool operator ==(covariant MainContentTopicModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.title == title &&
      other.subTitle == subTitle &&
      other.description == description &&
      other.contentImageUrl == contentImageUrl &&
      other.bioAnnotationInfo == bioAnnotationInfo;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      title.hashCode ^
      subTitle.hashCode ^
      description.hashCode ^
      contentImageUrl.hashCode ^
      bioAnnotationInfo.hashCode;
  }
}
