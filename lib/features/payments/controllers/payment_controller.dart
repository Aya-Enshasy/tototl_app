import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentController {
  final PaymentService service;
  PaymentController(this.service);

  bool isLoading = false;
  String? errorMessage;
  List<PaymentModel> payments = const [];

  Future<bool> loadPayments({
    required PaymentAudience audience,
    String? status,
  }) async {
    if (isLoading) return false;
    isLoading = true;
    errorMessage = null;
    try {
      payments = await service.getPayments(audience: audience, status: status);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }
}
