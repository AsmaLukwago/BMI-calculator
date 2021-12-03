import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../constants.dart';
import '../l10n/localization_util.dart';
import '../settings/settings.controller.dart';
import 'models/bmi.dart';
import 'models/bmi_view_model.dart';
import 'models/gender.dart';
import 'widgets/bmi_info.dart';
import 'widgets/bmi_result.dart';
import 'widgets/gender_toggle_button.dart';
import 'widgets/slider.dart';
import 'widgets/wave_painter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    Key? key,
    required this.settingsController,
  }) : super(key: key);

  final SettingsController settingsController;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Gender selectedGender = Gender.male;
  int height = 170;
  int weight = 65;
  bool isBmiCalculated = false;
  late Bmi bmiResult;

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;

    final state = ref.watch(bmiProvider);
    state.when(
      initial: () => isBmiCalculated = false,
      calculated: (bmi) {
        bmiResult = bmi;
        isBmiCalculated = true;
      },
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _AppBar(settingsController: widget.settingsController),
      ),
      backgroundColor: primaryColor.withOpacity(.1),
      body: deviceHeight < 700
          ? SingleChildScrollView(child: _buildBody())
          : _buildBody(),
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 32),
      child: DecoratedBox(
        decoration: actionButtonDecoration,
        child: FloatingActionButton.large(
          onPressed: isBmiCalculated
              ? () => _resetBmi(context, ref)
              : () => _calculateBmi(context, ref, height, weight),
          backgroundColor: Colors.white,
          elevation: 0,
          child: Icon(
            isBmiCalculated ? Icons.refresh : Icons.trending_flat,
            color: Theme.of(context).primaryColor,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final deviceSize = MediaQuery.of(context).size;

    return Center(
      child: Container(
        constraints: const BoxConstraints(minWidth: 375, maxWidth: 500),
        decoration: mainContainerDecoration,
        height: deviceSize.height < 700 ? 700 : deviceSize.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGenderText(),
                    _buildGenderButtons(),
                    _buildHeightText(),
                    _buildHeightSlider(),
                    _buildWeightText(),
                    _buildWeightSlider(),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 250,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  _buildBottomContent(),
                  _buildActionButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomContent() {
    return CustomPaint(
      painter: const WavePainter(),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 1000),
        firstChild: const BmiInfoWidget(),
        secondChild: isBmiCalculated
            ? BmiResultWidget(bmi: bmiResult)
            : const SizedBox(),
        crossFadeState: !isBmiCalculated
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
      ),
    );
  }

  Widget _buildGenderButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SizedBox(
              height: 45,
              child: _buildGenderToggleButton(
                title: l(context).male,
                gender: Gender.male,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 45,
              child: _buildGenderToggleButton(
                title: l(context).female,
                gender: Gender.female,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderText() {
    return Text(
      l(context).gender,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildGenderToggleButton({
    required Gender gender,
    required String title,
  }) {
    return GenderToggleButton(
      valueKey: ValueKey<String>('$gender'),
      onTap: () => _changeGender(gender),
      gender: gender,
      selectedGender: selectedGender,
      text: title,
    );
  }

  Widget _buildHeightSlider() {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 16),
      child: CustomSlider(
        min: 120,
        max: 220,
        measurementUnit: 'cm',
        value: height,
        onChanged: !isBmiCalculated
            ? (double newValue) {
                setState(() {
                  height = newValue.round();
                });
              }
            : null,
      ),
    );
  }

  Text _buildHeightText() {
    return Text(
      l(context).height,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildWeightSlider() {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 16),
      child: CustomSlider(
        min: 40,
        max: 120,
        measurementUnit: 'kg',
        value: weight,
        onChanged: !isBmiCalculated
            ? (double newValue) {
                setState(() {
                  weight = newValue.round();
                });
              }
            : null,
      ),
    );
  }

  Text _buildWeightText() {
    return Text(
      l(context).weight,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  void _calculateBmi(BuildContext ctx, WidgetRef ref, int height, int weight) {
    final model = ref.read(bmiProvider.notifier);
    model.calculate(height: height, weight: weight);
  }

  void _changeGender(Gender gender) {
    if (isBmiCalculated) {
      return;
    }

    setState(() {
      selectedGender = gender;
    });
  }

  void _resetBmi(BuildContext ctx, WidgetRef ref) {
    final model = ref.read(bmiProvider.notifier);
    model.reset();
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({
    Key? key,
    required this.settingsController,
  }) : super(key: key);

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AppBar(
      key: const ValueKey<String>('AppBar'),
      actions: [
        PopupMenuButton<Locale>(
          icon: SvgPicture.asset(
            LocalizationUtil.getAssetName(settingsController.locale),
          ),
          tooltip: l(context).changeLanguage,
          onSelected: (Locale locale) {
            if (settingsController.locale != locale) {
              settingsController.updateLocale(locale);
            }
          },
          itemBuilder: (context) => <PopupMenuEntry<Locale>>[
            PopupMenuItem<Locale>(
              value: localeEnglish,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(assetEnglish, height: 20, width: 20),
                      const SizedBox(width: 8),
                      Text(
                        l(context).english,
                        style: textTheme.bodyText2,
                      ),
                    ],
                  ),
                  if (settingsController.locale == localeEnglish)
                    Icon(Icons.check, color: theme.primaryColor),
                ],
              ),
            ),
            PopupMenuItem<Locale>(
              value: localeTurkish,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(assetTurkish, height: 20, width: 20),
                      const SizedBox(width: 8),
                      Text(
                        l(context).turkish,
                        style: textTheme.bodyText2,
                      ),
                    ],
                  ),
                  if (settingsController.locale == localeTurkish)
                    Icon(Icons.check, color: theme.primaryColor),
                ],
              ),
            ),
          ],
        ),
      ],
      backgroundColor: Colors.white,
      title: Text(l(context).title, style: appBarTextStyle),
    );
  }
}
