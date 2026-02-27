import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/auth/domain/models/custom_error.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:future_riverpod/features/auth/presentation/providers/user_profile_provider.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:go_router/go_router.dart';

class HomeTest extends ConsumerWidget {
  const HomeTest({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInformation = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome back ${userInformation.value?.first.firstName ?? "User"}',
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.goNamed(RouteNames.profile);
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: userInformation.when(
        data: (data) => ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final user = data[index];
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Welcome back ${user.firstName} ${user.secondName}!'),
                  Text(user.email),
                  AppButton.text(
                    onPressed: () {
                      ref.read(authRepositoryProvider).signOut();
                    },
                    label: 'Sign Out',
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
            );
          },
        ),
        error: (error, stack) {
          CustomError(message: error.toString());
          return null;
        },
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
