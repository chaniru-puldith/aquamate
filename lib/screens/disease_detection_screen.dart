import 'dart:io';

import 'package:aquamate/utils/constants.dart';
import 'package:aquamate/widgets/rounded_filled_button.dart';
import 'package:aquamate/widgets/rounded_outlined_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  String selectedDiseaseImagePath = '';
  final picker = ImagePicker();
  bool _isFound = false;
  String disease = '';

  @override
  void initState() {
    super.initState();
    _tfLteInit();
  }

  Future<void> _tfLteInit() async {
    await Tflite.loadModel(
        model: "assets/model/fish_disease.tflite",
        labels: "assets/model/disease_labels.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false);
  }

  _pickImage(ImageSource source) async {
    selectedDiseaseImagePath = '';

    final XFile? image = await picker.pickImage(source: source);

    if (image == null) return;

    setState(() {
      selectedDiseaseImagePath = image.path;
    });

    _getDisease(context);
  }

  void _showDiseaseImagePicker(BuildContext context) {
    showModalBottomSheet(
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        context: context,
        builder: (builder) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 5.2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0XFF212121),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Material(
                        color: const Color(0XFF212121),
                        child: InkWell(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.photo_library_outlined,
                                  color: Colors.white70,
                                  size: 22.0,
                                ),
                                kSizedBoxW10,
                                Text(
                                  "Gallery",
                                  textAlign: TextAlign.center,
                                  style: kFilledButtonTextStyle.copyWith(
                                    color: Colors.white70,
                                  ),
                                )
                              ],
                            ),
                          ),
                          onTap: () {
                            _pickImage(ImageSource.gallery);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    )),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.0),
                      child: Divider(
                        color: Colors.white12,
                      ),
                    ),
                    Expanded(
                        child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Material(
                        color: const Color(0XFF212121),
                        child: InkWell(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white70,
                                  size: 22.0,
                                ),
                                kSizedBoxW10,
                                Text(
                                  "Camera",
                                  textAlign: TextAlign.center,
                                  style: kFilledButtonTextStyle.copyWith(
                                    color: Colors.white70,
                                  ),
                                )
                              ],
                            ),
                          ),
                          onTap: () {
                            _pickImage(ImageSource.camera);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ))
                  ],
                )),
          );
        });
  }

  void _getDisease(BuildContext context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (builder) {
          return AlertDialog(
            insetPadding: const EdgeInsets.all(30),
            content: Container(
              padding: const EdgeInsets.all(20),
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                kSizedBoxH10,
                const Text(
                  'Selected Photo',
                  style: kFilledButtonTextStyle,
                ),
                kSizedBoxH10,
                SizedBox(
                  width: 120,
                  height: 120,
                  child: selectedDiseaseImagePath.isEmpty
                      ? CircleAvatar(
                          backgroundColor: Colors.grey.shade300,
                          child: const Icon(
                            Icons.account_circle_outlined,
                            color: Colors.black,
                            size: 70,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(selectedDiseaseImagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                kSizedBoxH20,
                RoundedFilledButton(
                  onPressed: () async {
                    _showLoading(context);

                    var output = await Tflite.runModelOnImage(
                      path: selectedDiseaseImagePath,
                      numResults:
                          5, // The number of classes your model predicts
                      threshold:
                          0.1, // Adjust this threshold as needed based on your model's confidence
                      imageMean:
                          0, // Default is 0 if you haven't applied any specific normalization during training
                      imageStd:
                          1, // Default is 1 if you haven't applied any specific normalization during training
                    );

                    if (output == null || output.isEmpty) {
                      print('No matches');
                    }

                    setState(() {
                      disease = output![0]['label'];
                      _isFound = true;
                    });

                    if (!mounted) return;
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Get Results',
                    style: kFilledButtonTextStyle.copyWith(fontSize: 12),
                  ),
                ),
                RoundedOutlinedButton(
                  onPressed: () {
                    setState(() {
                      selectedDiseaseImagePath = '';
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Discard',
                    style: kOutlinedButtonTextStyle.copyWith(fontSize: 12),
                  ),
                )
              ]),
            ),
          );
        });
  }

  void _showLoading(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            content: Align(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpinKitWaveSpinner(
                  size: 60,
                  color: kPrimaryThemeColor,
                  trackColor: kPrimaryThemeColor.withOpacity(0.5),
                  waveColor: Colors.blue.shade300.withOpacity(0.8),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Disease Detection',
          textAlign: TextAlign.center,
          style: kHeadlineTextStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              kSizedBoxH10,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: kPrimaryThemeColor.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.shade800, blurRadius: 5),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: selectedDiseaseImagePath.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.fileCircleXmark,
                                    color: kTextFieldUtilsColor,
                                    size: 100,
                                  ),
                                  kSizedBoxH10,
                                  Text('No image file selected'),
                                ],
                              )
                            : ClipRRect(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(16)),
                                child: Image.file(
                                  File(selectedDiseaseImagePath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              kSizedBoxH20,
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 55,
                child: RoundedFilledButton(
                  onPressed: () {
                    _showDiseaseImagePicker(context);
                  },
                  child: const Text(
                    'Select an Image',
                    style: kFilledButtonTextStyle,
                  ),
                ),
              ),
              kSizedBoxH30,
              kSizedBoxH30,
              Visibility(
                visible: _isFound,
                child: Column(
                  children: [
                    Text(
                      disease == 'Healthy'
                          ? 'Healthy Fish'
                          : 'Predicted Disease :  $disease',
                      style: kPoppinsBoldTextStyle,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}