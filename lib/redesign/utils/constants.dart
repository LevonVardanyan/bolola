import 'dart:io';
import '../services/api_key_service.dart';

const SORT_TYPE_MIXED = "0";
const SORT_TYPE_ORDER = "1";
const SORT_TYPE_POPULAR = "2";

final SORT_TYPE_MIXED_NAME = "Խառը";
final SORT_TYPE_ORDER_NAME = "Հերթականությամբ";
final SORT_TYPE_POPULAR_NAME = "Շատ օգտագործված";

const SEARCH_SORT_TYPE_ORDER = "4";
const SEARCH_SORT_TYPE_POPULAR = "5";

final SEARCH_SORT_TYPE_ORDER_NAME = "Ըստ համապատասխանության";
final SEARCH_SORT_TYPE_POPULAR_NAME = "Շատ օգտագործված";

String? get bulki => ApiKeyService().apiKey;
double screenHeight = 0;
double screenWidth = 0;

double POPUPS_CORNER = 14;

String mainCategoryName = "categories";
String reserveCategoryName1 = "categoriesReserveCopy1";
String reserveCategoryName2 = "categoriesReserveCopy2";

String aboutUsDescription = "Բոլոլա ծրագիրը ստեղծվել է էնտուզիազմի վրա հիմնված։ Այն ի սկզբանե ստեղծվեց ընկերական միջավայրում օգտագործելու համար, բայց մտածեցինք, ինչու չկիսվել բոլորի հետ։  Ծրագիրը չի հետապնդում շահույթ ստանալու նպատակներ և այն ապահովելու ծախսերը արվում են մեր կողմից, ծրագրում ցուցադրվող գովազդը ծախսը հնարավորինս ծածկելու համար է։ Հուսանք կհավանեք ծրագիրը և կկիսվեք ձեր ընկերների հետ";
String aboutUsTitle = "Ծրագրի մասին";

String getBannerAdUnitId() {
  if (Platform.isIOS) {
    return 'ca-app-pub-4342904486777207/1841965713';
  } else if (Platform.isAndroid) {
    return 'ca-app-pub-4342904486777207/1161285345';
  }
  return "ca-app-pub-4342904486777207/1161285345";
}

String getNativeVideoListUnitId() {
  if (Platform.isIOS) {
    return "ca-app-pub-4342904486777207/1118816953";
  } else if (Platform.isAndroid) {
    return "ca-app-pub-4342904486777207/2514028796";
  }
  return "ca-app-pub-4342904486777207/1118816953";
}

String getSortTypeName(String sortType) {
  switch (sortType) {
    case SEARCH_SORT_TYPE_ORDER:
      return SEARCH_SORT_TYPE_ORDER_NAME;
    case SEARCH_SORT_TYPE_POPULAR:
      return SEARCH_SORT_TYPE_POPULAR_NAME;
    case SORT_TYPE_ORDER:
      return SORT_TYPE_ORDER_NAME;

    case SORT_TYPE_POPULAR:
      return SORT_TYPE_POPULAR_NAME;

    case SORT_TYPE_MIXED:
      return SORT_TYPE_MIXED_NAME;
  }
  return SORT_TYPE_ORDER_NAME;
}
