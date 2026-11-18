import 'package:flutter/material.dart';

// display progress path of each suspect
// it shows how many clues were discovered about this suspect
// used in inventory

class ProgressPath extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final List<String>? images;

  const ProgressPath({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color.fromRGBO(158, 158, 158, 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isEven) {
            final step = index ~/ 2;
            final bool isCompleted = step < currentStep;
            final color = isCompleted ? Colors.green : Colors.grey.shade400;
            final imagePath =
                images != null && step < images!.length ? images![step] : null;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: 45,
              height: 45,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: imagePath != null
                  ? ClipOval(
                      child: Image.asset(imagePath, fit: BoxFit.cover),
                    )
                  : const SizedBox.shrink(),
            );
          } else {
            final lineIndex = (index - 1) ~/ 2;
            final bool isLineActive = lineIndex < currentStep - 1;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: 8,
                decoration: BoxDecoration(
                  color: isLineActive ? Colors.green : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }),
      ),
    );
  }
}
