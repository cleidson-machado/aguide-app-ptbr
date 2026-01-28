import 'package:portugal_guide/app/core/repositories/gen_crud_repository_interface.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';

abstract class MainContentTopicRepositoryInterface extends GenCrudRepositoryInterface<MainContentTopicModel> {

  Future<List<MainContentTopicModel>> searchByTitle(String title);

  Future<MainContentTopicModel?> findByUrl(String url);

  Future<List<MainContentTopicModel>> getAllPaged({required int page, required int size});
}