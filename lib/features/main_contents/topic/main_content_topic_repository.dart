// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:portugal_guide/app/core/repositories/gen_crud_repository.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/app/token/rest_api_token.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_repository_interface.dart';

/// Repository concreto que implementa a interface e herda o CRUD básico
class MainContentTopicRepository extends GenCrudRepository<MainContentTopicModel>
    implements MainContentTopicRepositoryInterface {
  
  MainContentTopicRepository()
      : super(
          endpoint: '/contents',
          fromMap: MainContentTopicModel.fromMap,
          dio: _setupDio(),
        );

  /// Configurações customizadas do Dio para esse Repository
  static Dio _setupDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvKeyHelperConfig.mocApi2,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final String passKey = RestApiToken.key;
          options.headers['Authorization'] = 'Bearer $passKey';
          return handler.next(options);
        },
      ),
    );

    return dio;
  }

  // #########################################################
  // ### SOBRESCREVENDO O MÉTODO getAll() PARA ESSA API ###
  // #########################################################
  
  @override
  Future<List<MainContentTopicModel>> getAll() async {
    print("🌐 [MainContentTopicRepository] Iniciando getAll()...");
    
    try {
      final response = await dioGenCrudRepo.get(endpointGenCrudRepo);
      print("🌐 [MainContentTopicRepository] Status: ${response.statusCode}");
      print("🌐 [MainContentTopicRepository] Response data type: ${response.data.runtimeType}");
      
      if (response.statusCode == 200) {
        // A API retorna um wrapper object, não um array direto
        final Map<String, dynamic> responseData = response.data as Map<String, dynamic>;
        print("🌐 [MainContentTopicRepository] Response keys: ${responseData.keys}");
        
        // Extrair o array "items" do wrapper
        final List<dynamic> itemsData = responseData['items'] as List<dynamic>;
        print("🌐 [MainContentTopicRepository] Encontrados ${itemsData.length} itens");
        
        // Converter cada item para MainContentTopicModel
        final List<MainContentTopicModel> items = itemsData.map((json) {
          print("🔄 [MainContentTopicRepository] Processando: ${json['id']} - ${json['title']}");
          return fromMap(json as Map<String, dynamic>);
        }).toList();
        
        print("✅ [MainContentTopicRepository] ${items.length} itens convertidos com sucesso");
        return items;
      }
      
      throw Exception('Failed to load items - Status: ${response.statusCode}');
    } catch (e, stackTrace) {
      print("❌ [MainContentTopicRepository] Erro em getAll(): $e");
      print("❌ [MainContentTopicRepository] StackTrace: $stackTrace");
      throw Exception('Error fetching items: $e');
    }
  }

  // #########################################################
  // ### MÉTODOS ESPECÍFICOS DESSA FEATURE ###
  // #########################################################

  @override
  Future<List<MainContentTopicModel>> searchByTitle(String title) async {
    print("🔍 [MainContentTopicRepository] Buscando por título: '$title'");
    
    // Para busca, vamos usar o getAll() e filtrar localmente
    // (a menos que sua API tenha um endpoint específico de busca)
    try {
      final allItems = await getAll();
      final filteredItems = allItems
          .where((item) => item.title.toLowerCase().contains(title.toLowerCase()))
          .toList();
      
      print("🔍 [MainContentTopicRepository] Encontrados ${filteredItems.length} itens para '$title'");
      return filteredItems;
    } catch (e) {
      print("❌ [MainContentTopicRepository] Erro na busca: $e");
      throw Exception('Error searching content by title: $e');
    }
  }

  @override
  Future<MainContentTopicModel?> findByUrl(String url) async {
    try {
      // Buscar todos e filtrar por URL
      final allItems = await getAll();
      final foundItem = allItems.where((item) => item.contentUrl == url).firstOrNull;
      
      print("🔍 [MainContentTopicRepository] Busca por URL '$url': ${foundItem != null ? 'encontrado' : 'não encontrado'}");
      return foundItem;
    } catch (e) {
      print("❌ [MainContentTopicRepository] Erro ao buscar por URL: $e");
      throw Exception('Error finding content by url: $e');
    }
  }
}