import 'package:flutter/material.dart';

class ModernProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> titles;

  const ModernProgressIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.titles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          // Curved connector line
          final lineIndex = (index - 1) ~/ 2;
          final isLineActive = lineIndex < currentStep - 1;

          return Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: isLineActive
                    ? LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                )
                    : LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                ),
              ),
            ),
          );
        } else {
          // Circle with colorful background and title inside
          final stepIndex = index ~/ 2;
          final isActive = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep - 1;

          Color bgColor = isActive ? Colors.purple : Colors.grey.shade300;
          Color textColor = isActive ? Colors.white : Colors.black87;

          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(colors: [Colors.blue, Colors.purple])
                  : null,
              color: isActive ? null : bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                if (isCurrent)
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ],
              /*border: Border.all(
                color: isCurrent ? Colors.deepOrange : Colors.transparent,
                width: 2,
              ),*/
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  titles[stepIndex],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ),
          );
        }
      }),
    );
  }
}
