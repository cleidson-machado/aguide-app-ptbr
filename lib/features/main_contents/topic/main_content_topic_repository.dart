// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps

import 'package:dio/dio.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/repositories/gen_crud_repository.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/auth/auth_http_interceptor.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_repository_interface.dart';

/// Repository concreto que implementa a interface e herda o CRUD básico
class MainContentTopicRepository
    extends GenCrudRepository<MainContentTopicModel>
    implements MainContentTopicRepositoryInterface {
  MainContentTopicRepository()
    : super(
        endpoint: '/contents',
        fromMap: MainContentTopicModel.fromMap,
        dio: _setupDio(),
      );

  /// Configurações customizadas do Dio para esse Repository
  /// ✅ Usa AuthHttpInterceptor global para tratamento centralizado de auth
  static Dio _setupDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvKeyHelperConfig.apiBaseUrl,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      ),
    );

    // ✅ NOVO: Interceptor global de autenticação
    final tokenManager = injector<AuthTokenManager>();
    final devToken = EnvKeyHelperConfig.tokenKeyForMocApi2;

    dio.interceptors.add(
      AuthHttpInterceptor(
        tokenManager,
        fallbackToken: devToken,
      ),
    );

    return dio;
  }

  // #########################################################
  // ### ANOTAÇÕES SOBRE o Override do getAll() ### volar e rever!
  // https://apps.abacus.ai/chatllm/?convoId=11f362b48e&appId=30ebe4a4
  // #########################################################

  // #########################################################
  // ### SOBRESCREVENDO O MÉTODO getAll() PARA QUE VEIO DA GenCrudRepository ###
  // #########################################################

  @override
  Future<List<MainContentTopicModel>> getAll() async {
    print("🌐 [MainContentTopicRepository] Iniciando getAll()...");

    try {
      final response = await dioGenCrudRepo.get(endpointGenCrudRepo);
      print("🌐 [MainContentTopicRepository] Status: ${response.statusCode}");
      print(
        "🌐 [MainContentTopicRepository] Response data type: ${response.data.runtimeType}",
      );

      if (response.statusCode == 200) {
        // A API retorna um wrapper object, não um array direto
        final Map<String, dynamic> responseData =
            response.data as Map<String, dynamic>;
        print(
          "🌐 [MainContentTopicRepository] Response keys: ${responseData.keys}",
        );

        // Extrair o array "items" do wrapper
        final List<dynamic> itemsData = responseData['items'] as List<dynamic>;
        print(
          "🌐 [MainContentTopicRepository] Encontrados ${itemsData.length} itens",
        );

        // Converter cada item para MainContentTopicModel
        final List<MainContentTopicModel> items =
            itemsData.map((json) {
              print(
                "🔄 [MainContentTopicRepository] Processando: ${json['id']} - ${json['title']}",
              );
              return fromMap(json as Map<String, dynamic>);
            }).toList();

        print(
          "✅ [MainContentTopicRepository] ${items.length} itens convertidos com sucesso",
        );
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
  // ### MÉTODOS ESPECÍFICOS DESSA FEATURE DE PESQUISA ###
  // #########################################################

  @override
  Future<List<MainContentTopicModel>> searchByTitle(String title) async {
    print("🔍 [MainContentTopicRepository] Buscando por título: '$title'");

    // Para busca, vamos usar o getAll() e filtrar localmente
    // (a menos que sua API tenha um endpoint específico de busca)
    try {
      final allItems = await getAll();
      final filteredItems =
          allItems
              .where(
                (item) =>
                    item.title.toLowerCase().contains(title.toLowerCase()),
              )
              .toList();

      print(
        "🔍 [MainContentTopicRepository] Encontrados ${filteredItems.length} itens para '$title'",
      );
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
      final foundItem =
          allItems.where((item) => item.videoUrl == url).firstOrNull;

      print(
        "🔍 [MainContentTopicRepository] Busca por URL '$url': ${foundItem != null ? 'encontrado' : 'não encontrado'}",
      );
      return foundItem;
    } catch (e) {
      print("❌ [MainContentTopicRepository] Erro ao buscar por URL: $e");
      throw Exception('Error finding content by url: $e');
    }
  }

  // #########################################################
  // ### NOVO MÉTODO PARA PAGINAÇÃO INCREMENTAL COM ORDENAÇÃO DINÂMICA ###
  // #########################################################

  @override
  Future<List<MainContentTopicModel>> getAllPaged({
    required int page,
    required int size,
    String? sortField,
    String? sortOrder,
  }) async {
    // ⚠️ IMPORTANTE: A API usa paginação ZERO-BASED (page=0 é a primeira página)
    // Converter de 1-based (usado no app) para 0-based (usado na API)
    final int apiPage = page - 1;

    // Parâmetros de ordenação (padrões da API: title e asc)
    final String sort = sortField ?? 'title';
    final String order = sortOrder ?? 'asc';

    print("📄 [MainContentTopicRepository] Iniciando getAllPaged()");
    print("   App Page: $page → API Page: $apiPage, Size: $size");
    print("   🎲 Ordenação: $sort ($order)");

    try {
      // ✅ Usando endpoint /contents com parâmetros flexíveis
      final response = await dioGenCrudRepo.get(
        endpointGenCrudRepo,
        queryParameters: {
          'page': apiPage, // ✅ Envia zero-based para a API
          'size': size,
          'sort': sort,
          'order': order,
        },
      );
      print("📄 [MainContentTopicRepository] Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        // A API retorna: {content: [...], totalItems: 91, totalPages: 2, currentPage: 0}
        final Map<String, dynamic> responseData =
            response.data as Map<String, dynamic>;

        // Extrair metadados de paginação
        final int totalItems = responseData['totalItems'] as int? ?? 0;
        final int totalPages = responseData['totalPages'] as int? ?? 0;
        final int currentPage = responseData['currentPage'] as int? ?? 0;

        print(
          "📊 [MainContentTopicRepository] Paginação - Total itens: $totalItems, Total páginas: $totalPages, Página atual (API): $currentPage",
        );

        // Extrair o array "content" (estrutura padrão Spring Boot PageImpl)
        final List<dynamic> contentData =
            responseData['content'] as List<dynamic>? ?? [];
        print(
          "📄 [MainContentTopicRepository] Encontrados ${contentData.length} itens na página $page (API page $apiPage)",
        );

        // Converter cada item para MainContentTopicModel
        final List<MainContentTopicModel> items =
            contentData.map((json) {
              return fromMap(json as Map<String, dynamic>);
            }).toList();

        print(
          "✅ [MainContentTopicRepository] ${items.length} itens convertidos com sucesso da página $page",
        );
        print(
          "📊 [MainContentTopicRepository] Progresso: ${(page * size).clamp(0, totalItems)}/$totalItems itens carregados",
        );

        return items;
      }

      throw Exception(
        'Failed to load paged items - Status: ${response.statusCode}',
      );
    } catch (e, stackTrace) {
      print("❌ [MainContentTopicRepository] Erro em getAllPaged(): $e");
      print("❌ [MainContentTopicRepository] StackTrace: $stackTrace");
      throw Exception('Error fetching paged items: $e');
    }
  }
}
