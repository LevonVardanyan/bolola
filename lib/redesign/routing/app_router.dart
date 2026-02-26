import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/pages/home_page.dart';
import 'package:politicsstatements/redesign/pages/sources_route.dart';
import 'package:politicsstatements/redesign/pages/aboute_route.dart';
import 'package:politicsstatements/redesign/pages/moderation_page.dart';
import 'package:politicsstatements/redesign/pages/media_group_page.dart';
import 'package:politicsstatements/redesign/pages/user_messages_page.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/resources/models/media_group.dart';

class AppRouter {
  static const String home = '/';
  static const String sources = '/sources';
  static const String about = '/about';
  static const String moderation = '/moderation';
  static const String mediaGroup = '/group';
  static const String userMessages = '/messages';

  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => HomePageRoute(),
          settings: settings,
        );

      case sources:
        return MaterialPageRoute(
          builder: (_) => SourcesRoute(),
          settings: settings,
        );

      case about:
        return MaterialPageRoute(
          builder: (_) => AboutRoute(),
          settings: settings,
        );

      case moderation:
        if (args is ModerationRouteArgs) {
          return MaterialPageRoute(
            builder: (_) => ModerationRoute(args.appBloc, args.type),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      case mediaGroup:
        if (args is MediaGroupRouteArgs) {
          return MaterialPageRoute(
            builder: (_) => MediaGroupRoute(args.appBloc, args.group),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      case userMessages:
        if (args is UserMessagesRouteArgs) {
          return MaterialPageRoute(
            builder: (_) => UserMessagesPage(appBloc: args.appBloc),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      default:
        return _errorRoute(settings);
    }
  }

  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('No route defined for ${settings.name}'),
        ),
      ),
      settings: settings,
    );
  }

  static void navigateToSources(BuildContext context) {
    Navigator.pushNamed(context, sources);
  }

  static void navigateToAbout(BuildContext context) {
    Navigator.pushNamed(context, about);
  }

  static void navigateToModeration(
    BuildContext context,
    AppBloc appBloc,
    String type,
  ) {
    Navigator.pushNamed(
      context,
      moderation,
      arguments: ModerationRouteArgs(appBloc: appBloc, type: type),
    );
  }

  static void navigateToMediaGroup(
    BuildContext context,
    AppBloc appBloc,
    MediaGroup group,
  ) {
    Navigator.pushNamed(
      context,
      mediaGroup,
      arguments: MediaGroupRouteArgs(appBloc: appBloc, group: group),
    );
  }

  static void navigateToUserMessages(
    BuildContext context,
    AppBloc appBloc,
  ) {
    Navigator.pushNamed(
      context,
      userMessages,
      arguments: UserMessagesRouteArgs(appBloc: appBloc),
    );
  }
}

class ModerationRouteArgs {
  final AppBloc appBloc;
  final String type;

  ModerationRouteArgs({
    required this.appBloc,
    required this.type,
  });
}

class MediaGroupRouteArgs {
  final AppBloc appBloc;
  final MediaGroup group;

  MediaGroupRouteArgs({
    required this.appBloc,
    required this.group,
  });
}

class UserMessagesRouteArgs {
  final AppBloc appBloc;

  UserMessagesRouteArgs({
    required this.appBloc,
  });
}
