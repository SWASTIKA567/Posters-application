import 'package:get/get.dart';

class HomeController extends GetxController {
  final featuredPosters = [
    {
      "title": "Matisse",
      "image": "assets/posters/poster1.jpg",
    },
    {
      "title": "Discipline",
      "image": "assets/posters/poster2.jpg",
    },
    {
      "title": "Flower",
      "image": "assets/posters/poster3.jpg",
    },
  ].obs;

  final recentPosters = [
    {
      "title": "Nature",
      "image": "assets/posters/poster4.jpg",
    },
    {
      "title": "Travel",
      "image": "assets/posters/poster5.jpg",
    },
  ].obs;
}