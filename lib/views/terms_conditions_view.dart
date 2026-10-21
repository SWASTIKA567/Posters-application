import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsConditionsView extends StatelessWidget {
  const TermsConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Center(
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0x1A8B0000),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.description_rounded, color: Color(0xFF8B0000), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Kechi Terms & Conditions",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Last Updated: October 2026",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Welcome to Kechi. These Terms & Conditions (\"Terms\") govern your access to and use of the Kechi mobile application, website, products, and services (\"Platform\"). By accessing Kechi, creating an account, placing an order, or using any of our services, you agree to be bound by these Terms. If you do not agree, please do not use Kechi.",
                    style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              number: "1",
              title: "About Kechi",
              content:
                  "Kechi is a poster-selling platform that allows customers to browse and purchase printed posters in A3, A4, and A5 sizes. Where available, Kechi may also allow customers to create customised posters using photographs or other content uploaded by them. Kechi currently delivers within the National Capital Region (NCR) only. Delivery to other locations will be introduced in future.",
            ),

            _buildSection(
              number: "2",
              title: "Eligibility",
              content:
                  "To use Kechi, you must:\n• Be at least 16 years of age. Users between 16 and 18 years of age must have the consent of a parent or legal guardian to use Kechi and place orders;\n• Provide accurate, complete, and current information when registering or placing an order; and\n• Have the legal capacity to enter into a binding agreement under applicable Indian law.\n\nIf you are using Kechi on behalf of another person or organisation, you represent that you have the authority to bind that person or organisation to these Terms.",
            ),

            _buildSection(
              number: "3",
              title: "Products, Pricing & GST",
              content:
                  "Kechi makes reasonable efforts to ensure that product descriptions, images, sizes, and prices displayed on the Platform are accurate. However:\n• All prices displayed are inclusive of applicable Goods and Services Tax (GST) unless explicitly stated otherwise.\n• Product colours may vary slightly depending on the display used to view them.\n• Printed posters may have minor variations in colour, trim, or alignment due to print batch or paper stock. Such variations are not considered defects.\n• Posters are printed on unlaminated paper stock unless otherwise stated. Customers are advised to consider this before placing an order.\n• The price applicable to an order is the price displayed at the time of order placement, subject to correction of obvious errors.\n• Kechi reserves the right to correct pricing or product information errors at any time.",
            ),

            _buildSection(
              number: "4",
              title: "Minimum Order Quantity & Delivery Area",
              content:
                  "The following conditions apply to all orders placed on Kechi:\n\nMinimum Order Quantity:\nEach order must contain a minimum of six (6) posters. Orders below this threshold will not be processed. Posters of different sizes (A3, A4, A5) may be combined to meet the minimum quantity.\n\nDelivery Area:\nKechi currently delivers within the National Capital Region (NCR), which includes Delhi, Noida, Gurgaon, Faridabad, and Ghaziabad. Orders from outside the NCR will not be processed at this time. Kechi will update these Terms when delivery is extended to other regions.",
            ),

            _buildSection(
              number: "5",
              title: "Custom Posters",
              content:
                  "Where custom poster functionality is available, the customer is solely responsible for all content uploaded for customisation. By uploading content, you confirm that:\n• You own the content or have obtained all necessary permissions to use it;\n• Your use of the content does not infringe any copyright, trademark, privacy, publicity, or other third-party rights;\n• The content does not violate any applicable laws or these Terms; and\n• You have the right to reproduce the content on a physical printed product.\n\nKechi reserves the right to refuse or cancel any customisation request if the submitted content appears to violate these Terms, applicable law, or the rights of any third party, without any obligation to provide a detailed explanation.",
            ),

            _buildSection(
              number: "6",
              title: "Prohibited Content",
              content:
                  "You must not upload or submit content through Kechi that:\n• Infringes copyright, trademark, or other intellectual property rights;\n• Contains illegal, obscene, defamatory, or fraudulent material;\n• Promotes violence, hatred, discrimination, or criminal activity;\n• Contains exploitative, abusive, or sexually explicit material;\n• Impersonates any person or entity;\n• Violates another person's privacy, publicity, or data protection rights; or\n• Otherwise violates applicable Indian law.\n\nKechi may reject or cancel orders involving prohibited content and may report such content to relevant authorities where required by law.",
            ),

            _buildSection(
              number: "7",
              title: "Intellectual Property",
              content:
                  "All Kechi branding, logos, application design, original poster artwork, graphics, text, and other materials created or owned by Kechi remain the exclusive property of Kechi or its licensors.\n\nPosters purchased from Kechi are licensed for personal, non-commercial use only. You may not reproduce, resell, redistribute, publicly display, or commercially exploit any Kechi poster design without prior written permission from Kechi.\n\nYou retain ownership of photographs and other content that you upload for custom poster creation. By uploading such content, you grant Kechi a limited, non-exclusive licence to use, process, and print that content solely for fulfilling your order.",
            ),

            _buildSection(
              number: "8",
              title: "Orders & Cash on Delivery (COD)",
              content:
                  "Order Confirmation:\nAn order is considered confirmed only after:\n• You have submitted the required order information and it meets the minimum quantity requirement;\n• Payment has been successfully received (prepaid) or the COD order has been explicitly confirmed by Kechi via WhatsApp or another written channel; and\n• Kechi has accepted and confirmed the order.\n\nSubmission of an order form or payment initiation alone does not constitute a confirmed order. Kechi reserves the right to cancel an order at any stage for reasons including:\n• Product unavailability;\n• Pricing or listing errors;\n• Delivery address falling outside the NCR service area;\n• Order not meeting the minimum quantity requirement;\n• Suspected fraud or misuse;\n• Invalid, incomplete, or unverifiable customer information;\n• Prohibited uploaded content; or\n• Circumstances beyond Kechi's reasonable control.\n\nCash on Delivery (COD):\nKechi offers Cash on Delivery as a payment option, subject to the following conditions:\n• COD is currently available within the NCR delivery area only.\n• COD orders must be confirmed by the customer via WhatsApp or a written channel before dispatch. Kechi reserves the right not to dispatch unconfirmed COD orders.\n• The customer must be available at the delivery address to receive the order and make payment at the time of delivery.\n• If a customer is unavailable at the time of delivery, Kechi or its courier partner may attempt re-delivery or cancel the order. Any re-delivery charges will be borne by the customer.\n• Repeated refusal of COD orders by a customer may result in COD being restricted or removed for that customer's account.\n• Kechi reserves the right to withdraw the COD option at any time without prior notice.",
            ),

            _buildSection(
              number: "9",
              title: "Payments",
              content:
                  "Prepaid payments may be processed through third-party payment providers such as Razorpay or other providers listed on the Platform at the time of checkout. Payment processing is subject to the terms and policies of the relevant payment provider.\n\nKechi does not request, collect, or store your payment PIN, CVV, password, OTP, or complete payment credentials. Never share such information with anyone claiming to represent Kechi.\n\nIn the event of a payment failure, please verify your payment status before placing a duplicate order. Contact us at support.kechi@gmail.com if a payment is debited but no order confirmation is received.",
            ),

            _buildSection(
              number: "10",
              title: "Shipping & Delivery",
              content:
                  "Kechi will make reasonable efforts to deliver orders within the estimated delivery timeframe communicated at the time of purchase. Estimated delivery times are indicative and not guaranteed.\n\nDelivery timelines may be affected by:\n• Production and printing time;\n• Courier partner availability and capacity;\n• Weather conditions, public holidays, or local disruptions;\n• Incorrect or incomplete delivery information provided by the customer; or\n• Other circumstances beyond Kechi's reasonable control.\n\nThe customer is responsible for providing an accurate and complete delivery address, including PIN code and a reachable contact number. Kechi is not responsible for delays, non-delivery, or additional charges resulting from incorrect or incomplete delivery information provided by the customer.",
            ),

            _buildSection(
              number: "11",
              title: "Returns, Cancellations & Refunds",
              content:
                  "Returns, cancellations, replacements, and refunds are governed by Kechi's Refund and Cancellation Policy, which is incorporated into these Terms by reference and available on the Platform.\n\nBecause customised posters are produced specifically for each customer, customised products may not be eligible for return or refund except in cases of manufacturing defects or incorrect items delivered.\n\nMinor colour variation or trim variance consistent with standard print production is not considered a defect. Please review the Refund and Cancellation Policy carefully before placing an order.\n\nCancellation of Customised Poster Orders:\nFor customised poster orders, cancellation is only available while the order is pending printing. Once printing has commenced, no cancellation request will be accepted or processed, and the order will proceed to dispatch.\nCustomers wishing to cancel a customised order must contact Kechi immediately at support.kechi@gmail.com or via WhatsApp (+91 9520266789) before printing begins. Kechi cannot guarantee cancellation even for pending orders if production has already started.\n\nProof of Delivery for Customised Orders:\nFor all customised poster orders, the designated delivery partner will capture a photograph of the delivered package at the time of delivery, as proof that the order was delivered in good condition to the correct address. This photograph will be available to Kechi and may be shared with the customer upon request.",
            ),

            _buildSection(
              number: "12",
              title: "User Accounts",
              content:
                  "Where Kechi provides account functionality, you are responsible for:\n• Maintaining the confidentiality of your account credentials;\n• All activities that occur through your account; and\n• Ensuring that the information associated with your account is accurate and up to date.\n\nYou agree to notify Kechi immediately at support.kechi@gmail.com if you suspect any unauthorised access to or use of your account. Kechi is not liable for any loss resulting from unauthorised account use where the customer has failed to maintain reasonable account security.",
            ),

            _buildSection(
              number: "13",
              title: "Privacy & Data",
              content:
                  "By using Kechi, you agree to our Privacy Policy, which governs how we collect, use, store, and protect your personal information. The Privacy Policy is available on the Platform and forms part of these Terms.\n\nKechi collects personal data such as your name, delivery address, phone number, and order history solely for the purpose of processing and delivering your orders, and improving the Platform experience. We do not sell your personal data to third parties.",
            ),

            _buildSection(
              number: "14",
              title: "Limitation of Liability",
              content:
                  "Kechi makes reasonable efforts to keep its Platform available, accurate, and functional. However, we do not guarantee that the application or website will always be uninterrupted or error-free.\n\nNothing in these Terms limits any rights you may have as a consumer under the Consumer Protection Act, 2019 or other applicable Indian law. To the extent permitted by law, Kechi's liability for any claim arising from the use of our Platform, products, or services is limited to the amount paid by the customer for the specific order giving rise to the claim.\n\nKechi is not liable for losses resulting from circumstances beyond our reasonable control, including but not limited to courier delays, force majeure events, or third-party platform outages.",
            ),

            _buildSection(
              number: "15",
              title: "Suspension or Termination",
              content:
                  "Kechi may suspend or terminate access to an account or service if a user:\n• Violates these Terms;\n• Engages in fraudulent or abusive activity;\n• Uploads prohibited or unlawful content;\n• Repeatedly refuses COD orders after confirmation; or\n• Uses the Platform in a manner that may harm Kechi, other users, or third parties.\n\nWhere possible, Kechi will notify the user before suspension or termination. In cases of serious or repeated violations, access may be terminated immediately without prior notice.",
            ),

            _buildSection(
              number: "16",
              title: "Changes to These Terms",
              content:
                  "Kechi may update these Terms from time to time to reflect changes in our services, operations, or applicable law. Updated Terms will be published on the Platform with a revised \"Last Updated\" date.\n\nYour continued use of Kechi after updated Terms are published constitutes your acceptance of the revised Terms. We encourage you to review these Terms periodically.",
            ),

            _buildSection(
              number: "17",
              title: "Governing Law & Disputes",
              content:
                  "These Terms are governed by and construed in accordance with the laws of India, including the Consumer Protection Act 2019, the Information Technology Act 2000, and other applicable legislation.\n\nAny disputes arising from or relating to these Terms or the use of Kechi shall first be attempted to be resolved through good-faith communication between the customer and Kechi. If unresolved, disputes shall be subject to the jurisdiction of the courts having appropriate jurisdiction over Kechi's registered place of business.",
            ),

            _buildSection(
              number: "18",
              title: "Contact Us",
              content:
                  "For questions, complaints, or support related to these Terms or any order, please contact us:\n\n• Entity: Kechi\n• Email: support.kechi@gmail.com\n• Phone: +91 9520266789\n• WhatsApp: +91 9520266789\n• Address: Mahagunpuram, Ghaziabad, NCR, India\n\nWe aim to respond to all queries within 2 business days.",
              isLast: true,
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                "© Kechi. All rights reserved.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ),
          if (!isLast) ...[
            const SizedBox(height: 18),
            Divider(color: Colors.grey.shade200, height: 1),
          ],
        ],
      ),
    );
  }
}
