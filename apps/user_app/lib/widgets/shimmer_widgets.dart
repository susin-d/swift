import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class VendorCardShimmer extends StatelessWidget {
  const VendorCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(width: double.infinity, height: 160, borderRadius: 20),
          const SizedBox(height: 16),
          const ShimmerLoading(width: 200, height: 20),
          const SizedBox(height: 8),
          Row(
            children: [
              const ShimmerLoading(width: 80, height: 16),
              const SizedBox(width: 12),
              const ShimmerLoading(width: 60, height: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryShimmer extends StatelessWidget {
  const CategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          const ShimmerLoading(width: 65, height: 65, borderRadius: 20),
          const SizedBox(height: 8),
          const ShimmerLoading(width: 50, height: 12),
        ],
      ),
    );
  }
}

class MenuItemShimmer extends StatelessWidget {
  const MenuItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const ShimmerLoading(width: 80, height: 80, borderRadius: 16),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading(width: 140, height: 18),
                const SizedBox(height: 8),
                const ShimmerLoading(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                const ShimmerLoading(width: 60, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
