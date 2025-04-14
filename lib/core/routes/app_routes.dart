class AppRoutes {
  /// The Initial Page
  static const introLogin = '/intro_login';
  static const onboarding = '/onboarding';

  /* <---- Login, Signup -----> */
  static const login = '/login';
  static const signup = '/signup';
  static const loginOrSignup = '/loginOrSignup';
  static const numberVerification = '/numberVerification';
  static const forgotPassword = '/forgotPassword';
  static const passwordReset = '/passwordReset';

  /* <---- ENTRYPOINT -----> */
  static const entryPoint = '/entry_point';
  static const entryPointAdmin = '/entry_point_admin';

  /* <---- Products Order Process -----> */
  static const home = '/home';
  static const newItems = '/newItems';
  static const pembelianPage = '/pembelian-page';
  static const addProduct= '/add-produk';
  static const addPembelian= '/add-pembelian';
  static const addUser= '/add-userr';
  static const addMember= '/add-member';
  static const editProduct= '/edit-produk';
  static const editUser= '/edit-user';
  static const updateStokProduct= '/edit-stok-produk';
  static const resultPembelian = '/result-pembelian';
  static const isMember= '/isMember';
  static const popularItems = '/popularItems';
  static const bundleProduct = '/bundleProduct';
  static const createMyPack = '/createMyPack';
  static const bundleDetailsPage = '/bundleDetailsPage';
  static const productDetails = '/productDetails';
  static const cartPage = '/cartPage';
  static const savePage = '/favouriteList';
  static const checkoutPage = '/checkoutPage';

  /// Order Status
  static const orderSuccessfull = '/orderSuccessfull';
  static const orderFailed = '/orderFailed';
  static const noOrderYet = '/noOrderYet';

  /// Category
  static const category = '/category';
  static const categoryDetails = '/categoryDetails';

  /// Search Page
  static const search = '/search';
  static const searchResult = '/searchResult';

  /* <---- Profile & Settings -----> */
  static const profile = 'profile';
  static const myOrder = '/myOrder';
  static const orderDetails = '/orderDetails';
  static const coupon = '/coupon';
  static const couponDetails = '/couponDetails';
  static const deliveryAddress = '/deliveryAddress';
  static const newAddress = '/newAddress';
  static const orderTracking = '/orderTracking';
  static const profileEdit = '/profileEdit';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const settingsLanguage = '/settingsLanguage';
  static const settingsNotifications = '/settingsNotifications';
  static const changePassword = '/changePassword';
  static const changePhoneNumber = '/changePhoneNumber';

  /* <---- Review and Comments -----> */
  static const review = '/review';
  static const submitReview = '/submitReview';
  // Not Needed
  // static const errorPage = '/errorPage';

  /* <---- Drawer Page -----> */
  static const drawerPage = '/drawerPage';
  static const aboutUs = '/aboutUs';
  static const faq = '/faq';
  static const termsAndConditions = '/termsAndConditions';
  static const help = '/help';
  static const contactUs = '/contactUs';

  /* <---- Payment Method -----> */
  static const paymentMethod = '/paymentMethod';
  static const paymentCardAdd = '/paymentCardAdd';
}
