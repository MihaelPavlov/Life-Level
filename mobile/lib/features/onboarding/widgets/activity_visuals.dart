import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';

String activityIcon(String type) => switch (type.toLowerCase()) {
      'running' => AppIcons.activityRunning,
      'cycling' => AppIcons.activityCycling,
      'gym' => AppIcons.activityGym,
      'yoga' => AppIcons.activityYoga,
      'swimming' => AppIcons.activitySwimming,
      'climbing' => AppIcons.activityRockClimbing,
      'hiking' => AppIcons.activityHiking,
      'walking' => AppIcons.activityHiking,
      _ => AppIcons.activityGym,
    };

Color activityColor(String type) => switch (type.toLowerCase()) {
      'running' => AppColors.green,
      'cycling' => AppColors.blue,
      'gym' => AppColors.red,
      'yoga' => AppColors.purple,
      'swimming' => const Color(0xFF39C5CF),
      'climbing' => const Color(0xFFDB6D28),
      'hiking' || 'walking' => const Color(0xFF7EE2B8),
      _ => AppColors.textSecondary,
    };

/// "Running", "Gym session" … as shown in feeds.
String activityLabel(String type) => switch (type.toLowerCase()) {
      'gym' => 'Gym session',
      _ => type.isEmpty ? 'Workout' : '${type[0].toUpperCase()}${type.substring(1).toLowerCase()}',
    };

/// The sport(s) that build toward a class, as a short phrase.
String classSportLabel(String className) => switch (className.toLowerCase()) {
      'ranger' => 'Running + cycling',
      'warrior' => 'Gym',
      'mystic' => 'Yoga',
      'tidecaller' => 'Swimming',
      'cragborn' => 'Climbing',
      'wayfarer' => 'Hiking + walking',
      _ => className,
    };

/// The activity icon that best represents a class group.
String classSportIcon(String className) => switch (className.toLowerCase()) {
      'ranger' => AppIcons.activityRunning,
      'warrior' => AppIcons.activityGym,
      'mystic' => AppIcons.activityYoga,
      'tidecaller' => AppIcons.activitySwimming,
      'cragborn' => AppIcons.activityRockClimbing,
      'wayfarer' => AppIcons.activityHiking,
      _ => AppIcons.activityGym,
    };
