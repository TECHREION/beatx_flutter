// ignore_for_file: unused_element, unused_field

import 'package:flutter/foundation.dart';

base class ApiEndpoints {
  static const String socketUrl = _RemoteServer.socketUrl;
  static const String baseUrl = _RemoteServer.baseUrl;

  /// ### post
  static const String login = _Auth.login;
  static const String logout = _Auth.logout;
  static const String socialLogin = _Auth.socialLogin;
  static const String signup = _Auth.signup;
  static const String verifyCode = _Auth.verifyCode;
  static const String forgetPassword = _Auth.forgetPassword;
  static const String createNewPassword = _Auth.resetPassword;
  static const String refreshToken = _Auth.refreshToken;
  static const String helpSupport = _HelpSupport.helpSupport;
  static const String getInterests = _Interest.getallInterests;
  static const String verification = _Verification.verification;

  //---------------report----------------

  /// ### post
  static const String sendReport = _Report.sendReport;

  //------------notification----------------
  /// ### get
  static const String getAllNotifications = _Notification.getAllNotifications;
  static const String readAllNotifications = _Notification.readAllNotifications;

  //------------checklist----------------
  /// ### get
  static const String getAllChecklistItems = _Checklist.getAllChecklistItems;

  static String getChecklistItemById(String id) =>
      _Checklist.getChecklistItemById(id);

  /// ### patch
  static String toggleChecklistItemCompletion({
    required String checklistId,
    required String itemId,
  }) => _Checklist.toggleChecklistItemCompletion(
    checklistId: checklistId,
    itemId: itemId,
  );
  static const String createChecklist = _Checklist.createChecklist;

  //-------------safety tips----------------
  static const String getAllSafetyTips = _SafetyTips.getAllSafetyTips;
  static String getSafetyTipById(String id) => _SafetyTips.getSafetyTipById(id);

  /// ### patch
  static String markNotificationAsRead({required String notificationId}) =>
      _Notification.markNotificationAsRead(notificationId);

  /// ### patch
  static const String markAllAsRead = _Notification.markAllAsRead;

  //----------------------chat----------------

  /// ### get
  static const String getChatRooms = _Chat.getChatRooms;
  static const String sendChatMessage = _Chat.sendChatMessage;
  static const String getAllHistory = _Chat.getAllHistory;
  static String deleteConversation(String id) => _Chat.deleteConversation(id);
  static String getConversationbyID(String id) => _Chat.getConversationbyID(id);

  // ---------------------- USER -----------------------------
  /// ### get
  static String getuserbyId = _User.getuserbyId;
  static String updateProfile = _User.updateProfile;
  static String changePassword = _User.changePassword;
  static String userPreferences = _User.preferences;

  // ---------------------- Products -----------------------------
  static const String getAllProducts = _Product.getAllProducts;

  static const String getSearchbytext = _Search.getSearchbytext;
  static const String getSearchbyimage = _Search.getSearchbyimage;
  static const String getSearchbyvoice = _Search.getSearchbyvoice;

  //-------------------------Filter --------------------------
  static const String getProductsByFilter = _Filter.getProductsByFilter;

  //-------------------------Category --------------------------
  static const String getAllCategories = _Category.getAllCategories;

  //-------------------------cart --------------------------
  static const String addToCart = _Cart.addToCart;
  static const String getAllCartItems = _Cart.getAllCartItems;
  static const String clearCart = _Cart.clearCart;
  static const String updateCart = _Cart.updateCart;

  //-------------------------Shop --------------------------
  static String getShop(String id) => _Shop.getShop(id);

  //------------------------- Order --------------------------
  static const String getMyOrders = _Order.getMyOrders;
  static const String createOrder = _Order.createOrder;

  //------------------------- Review --------------------------
  static const String addReview = _Review.addReview;

  //------------------------- WishList --------------------------
  static const String addWishList = _WishList.addWishList;
  static String removeWishList(String id) => _WishList.removeWishList(id);
  static const String getWishList = _WishList.getWishList;

  //-------------------------Messaging --------------------------
  static const String createChat = _Messaging.createChat;
  static const String sendNewMessage = _Messaging.sendNewMessage;
  static const String message = _Messaging.message;
  static const String getAllChats = _Messaging.getAllChats;
  static String getChat(String id) => _Messaging.getChat(id);
  static String markChatAsRead(String id) => _Messaging.markChatAsRead(id);

  static const String getAllSuppliers = _Supplier.getAllSuppliers;
  static String getSupplierbyId(String id) => _Supplier.getSupplierbyId(id);

  static const String getAllServices = _Service.getAllServices;
  static String getServicebyid(String id) => _Service.getServicebyid(id);

  //--------------------------banners--------------------------
  static const String getAllBanners = _Banner.getAllBanners;
}

//arrow360degree@gmail.com

class _RemoteServer {
  static const String socketUrl =
      'https://backend-mattiaiarriccio.onrender.com';

  static const String baseUrl =
      'https://backend-mattiaiarriccio.onrender.com/api/v1';
}

class _LocalHostWifi {
  static const String socketUrl = 'http://10.10.5.46:5001';
  static const String baseUrl = 'http://10.10.5.46:5001/api/v1';
}

class _Auth {
  @protected
  static const String _authRoute = '${ApiEndpoints.baseUrl}/auth';
  static const String login = '$_authRoute/login';
  static const String logout = '$_authRoute/logout';
  static const String socialLogin = '$_authRoute/social-login';
  static const String signup = '$_authRoute/register';
  static const String forgetPassword = '$_authRoute/password-reset/request';
  static const String refreshToken = '$_authRoute/refresh-token';
  static const String verifyCode = '$_authRoute/password-reset/verify';
  static const String resetPassword = '$_authRoute/password-reset/reset';
}

//------------------------------ Help&Support -----------------------------
class _HelpSupport {
  static const String _helpSupportRoute = '${ApiEndpoints.baseUrl}/support';
  static const String helpSupport = '$_helpSupportRoute/';
}

//------------------------------ Interest -----------------------------
class _Interest {
  static const String _interestRoute = '${ApiEndpoints.baseUrl}/interest';
  static const String getallInterests = '$_interestRoute/';
}

// ---------------------- Verification -----------------------------
class _Verification {
  static const String _verificationRoute =
      '${ApiEndpoints.baseUrl}/verification';
  static const String verification = '$_verificationRoute/create';
}

// ---------------------- Report -----------------------------
class _Report {
  static const String _reportRoute = '${ApiEndpoints.baseUrl}/reports';
  static const String sendReport = '$_reportRoute/';
}

// ---------------------- Notification -----------------------------
class _Notification {
  static const String _notificationRoute =
      '${ApiEndpoints.baseUrl}/notifications';
  static String markNotificationAsRead(String notificationId) =>
      '$_notificationRoute/$notificationId/read/';
  static const String readAllNotifications =
      '$_notificationRoute/mark-all-as-read';
  static const String markAllAsRead = '$_notificationRoute/mark-all-as-read';
  static const String getAllNotifications = '$_notificationRoute/';
}

class _Checklist {
  static const String _checklistRoute = '${ApiEndpoints.baseUrl}/checklists';
  static const String getAllChecklistItems = '$_checklistRoute/';
  static String getChecklistItemById(String id) => '$_checklistRoute/$id';

  static String toggleChecklistItemCompletion({
    required String checklistId,
    required String itemId,
  }) => '$_checklistRoute/$checklistId/items/$itemId';
  static const String createChecklist = _checklistRoute;
}

//---------------------- Safety Tips -----------------------------
class _SafetyTips {
  static const String _safetyTipsRoute = '${ApiEndpoints.baseUrl}/safety-tips';
  static const String getAllSafetyTips = _safetyTipsRoute;
  static String getSafetyTipById(String id) => '$_safetyTipsRoute/$id';
}

// ---------------------- USER -----------------------------
class _User {
  static const String _userRoute = '${ApiEndpoints.baseUrl}/users';
  static String getuserbyId = '$_userRoute/me';
  static String updateProfile = '$_userRoute/me';
  static String changePassword = '$_userRoute/me/password';
  static String preferences = '$_userRoute/me/preferences';
}

//-----------------------chat----------------
class _Chat {
  static const String _chatRoute = '${ApiEndpoints.baseUrl}/chat';
  static const String getChatRooms = '$_chatRoute/conversations';
  static const String sendChatMessage = '$_chatRoute/messages';
  static const String getAllHistory = '$_chatRoute/conversations';
  static String getConversationbyID(String id) =>
      '$_chatRoute/conversations/$id';
  static String deleteConversation(String id) =>
      '$_chatRoute/conversations/$id';
}

// ---------------------- Products -----------------------------
class _Product {
  static const String _productRoute = '${ApiEndpoints.baseUrl}/product';
  static const String getAllProducts = _productRoute;
}

class _Search {
  static const String _searchRoute = '${ApiEndpoints.baseUrl}/search';
  static const String getSearchbytext = '$_searchRoute/products';
  static const String getSearchbyimage = '$_searchRoute/products';
  static const String getSearchbyvoice = '$_searchRoute/products';
}

class _Filter {
  static const String _filterRoute = '${ApiEndpoints.baseUrl}/filter';
  static const String getProductsByFilter = '$_filterRoute/products';
}

//---------------------- Category -----------------------------
class _Category {
  static const String _categoryRoute = '${ApiEndpoints.baseUrl}/category';
  static const String getAllCategories = '$_categoryRoute/tree/all';
}

//---------------------- Cart -----------------------------
class _Cart {
  static const String _cartRoute = '${ApiEndpoints.baseUrl}/cart';
  static const String addToCart = '$_cartRoute/add';
  static const String getAllCartItems = '$_cartRoute/';
  static const String clearCart = '$_cartRoute/clear';
  static const String updateCart = '$_cartRoute/update';
}

//---------------------- Shop -----------------------------
class _Shop {
  static const String _shopRoute = '${ApiEndpoints.baseUrl}/shop';
  static String getShop(String id) => '$_shopRoute/$id';
}

//---------------------- Order -----------------------------
class _Order {
  static const String _orderRoute = '${ApiEndpoints.baseUrl}/order';
  static const String getMyOrders = '$_orderRoute/';
  static const String createOrder = '$_orderRoute/create';
}

//---------------------- Review -----------------------------
class _Review {
  static const String _reviewRoute = '${ApiEndpoints.baseUrl}/reviews';
  static const String addReview = '$_reviewRoute/';
}

//---------------------- WishList -----------------------------
class _WishList {
  static const String _wishListRoute = '${ApiEndpoints.baseUrl}/wishlist';
  static const String addWishList = '$_wishListRoute/toggle';
  static String removeWishList(String id) => '$_wishListRoute/$id';
  static const String getWishList = '$_wishListRoute/';
}

//----------------------Message -----------------------------
class _Messaging {
  static const String _messagingRoute = '${ApiEndpoints.baseUrl}/chat';
  static String getChat(String id) => '$_messagingRoute/$id';
  static String markChatAsRead(String id) => '$_messagingRoute/$id/read';
  static const String sendNewMessage = '$_messagingRoute/messages';
  static const String message = '$_messagingRoute/messages';
  static const String createChat = '$_messagingRoute/';
  static const String getAllChats = '$_messagingRoute/';
}

class _Supplier {
  static const String _supplierRoute = '${ApiEndpoints.baseUrl}/user';
  static const String getAllSuppliers = '$_supplierRoute/';
  static String getSupplierbyId(String id) => '$_supplierRoute/$id';
}

class _Service {
  static const String _serviceRoute = '${ApiEndpoints.baseUrl}/service';
  static const String getAllServices = '$_serviceRoute/';
  static String getServicebyid(String id) => '$_serviceRoute/$id';
}

class _Banner {
  static const String _bannerRoute = '${ApiEndpoints.baseUrl}/banner';
  static const String getAllBanners = '$_bannerRoute/';
}
