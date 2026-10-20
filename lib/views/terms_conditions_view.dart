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
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B0000).withOpacity(0.1),
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
                  const SizedBox(height: 6),
                  const Text(
                    "Welcome to Kechi. These Terms & Conditions (\"Terms\") govern your access to and use of the Kechi mobile application, website, products, and services (\"Platform\"). By accessing Kechi, creating an account, placing an order, or using any of our services, you agree to be bound by these Terms.",
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
                  "Kechi is a poster-selling platform that allows customers to browse and purchase printed posters in A3, A4, and A5 sizes. Where available, Kechi may also allow customers to create customised posters using photographs or other content uploaded by them. Kechi currently delivers within the National Capital Region (NCR) and pan-India via express courier partners.",
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
                  "Kechi makes reasonable efforts to ensure that product descriptions, images, sizes, and prices displayed on the Platform are accurate. However:\n• All prices displayed are inclusive of applicable Goods and Services Tax (GST) unless explicitly stated otherwise.\n• Product colours may vary slightly depending on the display used to view them.\n• Printed posters may have minor variations in colour, trim, or alignment due to print batch or paper stock. Such variations are not considered defects.\n• Posters are printed on premium 300 GSM archival stock using high-definition pigment inks.\n• The price applicable to an order is the price displayed at the time of order placement, subject to correction of obvious errors.\n• Kechi reserves the right to correct pricing or product information errors at any time.",
            ),

            _buildSection(
              number: "4",
              title: "Order Quantity & Delivery Area",
              content:
                  "The following conditions apply to orders placed on Kechi:\n• Available Sizes: A5 (₹39), A4 (₹59), A3 (₹99).\n• Delivery Charges: Flat ₹39 delivery fee across India. Orders containing 7 or more posters automatically unlock 100% FREE Delivery.\n• Delivery Coverage: Orders are dispatched via tracked courier partners (including Shadowfax Express) with live tracking links.",
            ),

            _buildSection(
              number: "5",
              title: "Custom Posters",
              content:
                  "Where custom poster functionality is available, the customer is solely responsible for all content uploaded for customisation. By uploading content, you confirm that:\n• You own the content or have obtained all necessary permissions to use it;\n• Your use of the content does not infringe any copyright, trademark, privacy, publicity, or other third-party rights;\n• The content does not violate any applicable laws or these Terms; and\n• You have the right to reproduce the content on a physical printed product.\n\nKechi reserves the right to refuse or cancel any customisation request if submitted content appears to violate these Terms, without obligation to provide explanation.",
            ),

            _buildSection(
              number: "6",
              title: "Prohibited Content",
              content:
                  "You must not upload or submit content through Kechi that:\n• Infringes copyright, trademark, or other intellectual property rights;\n• Contains illegal, obscene, defamatory, or fraudulent material;\n• Promotes violence, hatred, discrimination, or criminal activity;\n• Contains exploitative, abusive, or sexually explicit material;\n• Impersonates any person or entity;\n• Violates another person's privacy or data protection rights; or\n• Otherwise violates applicable Indian law.\n\nKechi may reject or cancel orders involving prohibited content and report such content to relevant authorities where required by law.",
            ),

            _buildSection(
              number: "7",
              title: "Intellectual Property",
              content:
                  "All Kechi branding, logos, application design, original poster artwork, graphics, text, and other materials created or owned by Kechi remain the exclusive property of Kechi or its licensors.\n\nPosters purchased from Kechi are licensed for personal, non-commercial use only. You may not reproduce, resell, redistribute, or commercially exploit any Kechi poster design without prior written permission.\n\nYou retain ownership of photographs and other content uploaded for custom poster creation. By uploading such content, you grant Kechi a limited, non-exclusive licence solely for fulfilling your order.",
            ),

            _buildSection(
              number: "8",
              title: "Orders & Cash on Delivery (COD)",
              content:
                  "Order Confirmation:\nAn order is considered confirmed only after required order information is submitted, payment has been successfully received (prepaid) or COD order has been confirmed, and Kechi has accepted the order.\n\nKechi reserves the right to cancel an order at any stage for reasons including product unavailability, pricing errors, suspected fraud, prohibited uploaded content, or circumstances beyond reasonable control.\n\nCash on Delivery (COD):\n• COD orders must be confirmed before dispatch.\n• The customer must be available at the delivery address to receive and make payment.\n• Repeated refusal of COD orders may result in COD being restricted for that customer account.\n• Kechi reserves the right to withdraw COD at any time without prior notice.",
            ),

            _buildSection(
              number: "9",
              title: "Payments",
              content:
                  "Prepaid payments may be processed through third-party payment providers such as Razorpay or other providers listed on the Platform at checkout. Payment processing is subject to the terms and policies of the relevant payment provider.\n\nKechi does not request, collect, or store your payment PIN, CVV, password, OTP, or complete payment credentials. Never share such information with anyone claiming to represent Kechi.\n\nIn the event of a payment failure, please verify your payment status before placing a duplicate order. Contact support.kechi@gmail.com if payment is debited but no order confirmation is received.",
            ),

            _buildSection(
              number: "10",
              title: "Shipping & Delivery",
              content:
                  "Kechi will make reasonable efforts to deliver orders within the estimated delivery timeframe (typically 3 to 5 business days after 24-48h dispatch). Estimated delivery times are indicative and not guaranteed.\n\nDelivery timelines may be affected by production time, courier capacity, weather conditions, holidays, or incorrect delivery information.\n\nThe customer is responsible for providing an accurate and complete delivery address, including PIN code and reachable contact number.",
            ),

            _buildSection(
              number: "11",
              title: "Returns, Cancellations & Replacements",
              content:
                  "• 2-Hour Cancellation Window: You can cancel your order directly from the app within 2 hours of placing it. After 2 hours, custom posters automatically enter high-definition printing production and cancellation is locked.\n\n• Defective / Damaged Posters (Strict 24-Hour Reporting): In the rare event your poster arrives damaged, bent, or with a printing defect, report it directly within the app or email support.kechi@gmail.com within 24 hours of delivery along with clear defect photos. Claims reported after 24 hours cannot be accepted.\n\n• 100% Free Replacement: For any verified genuine defect or transit damage, we dispatch an immediate 100% Free Replacement (Reprint) to your doorstep at zero extra charge. No monetary cash refunds are issued after delivery.\n\n• Minor colour or trim variance consistent with standard print production is not considered a defect.\n\n• Proof of Delivery: For customised poster orders, courier partners capture delivery photographs as proof that package was delivered in good condition.",
            ),

            _buildSection(
              number: "12",
              title: "User Accounts",
              content:
                  "Where Kechi provides account functionality, you are responsible for maintaining the confidentiality of your account credentials, all activities under your account, and keeping info up to date.\n\nNotify Kechi immediately at support.kechi@gmail.com if you suspect unauthorized access to your account.",
            ),

            _buildSection(
              number: "13",
              title: "Privacy & Data",
              content:
                  "By using Kechi, you agree to our Privacy Policy, which governs how we collect, use, store, and protect your personal information. The Privacy Policy is available on the Platform and forms part of these Terms.\n\nWe do not sell your personal data to third parties.",
            ),

            _buildSection(
              number: "14",
              title: "Limitation of Liability",
              content:
                  "Kechi makes reasonable efforts to keep its Platform available, accurate, and functional. However, we do not guarantee uninterrupted or error-free service.\n\nNothing in these Terms limits consumer rights under the Consumer Protection Act, 2019. To the extent permitted by law, Kechi's liability is limited to the amount paid by the customer for the specific order giving rise to the claim.\n\nKechi is not liable for losses resulting from courier delays, force majeure events, or third-party platform outages.",
            ),

            _buildSection(
              number: "15",
              title: "Suspension or Termination",
              content:
                  "Kechi may suspend or terminate access to an account or service if a user violates these Terms, engages in fraudulent activity, uploads prohibited content, repeatedly refuses confirmed COD orders, or harms the Platform.\n\nIn cases of serious or repeated violations, access may be terminated immediately without prior notice.",
            ),

            _buildSection(
              number: "16",
              title: "Changes to These Terms",
              content:
                  "Kechi may update these Terms from time to time. Updated Terms will be published on the Platform with a revised \"Last Updated\" date.\n\nYour continued use of Kechi after updated Terms are published constitutes your acceptance of the revised Terms.",
            ),

            _buildSection(
              number: "17",
              title: "Governing Law & Disputes",
              content:
                  "These Terms are governed by and construed in accordance with the laws of India, including the Consumer Protection Act 2019 and the Information Technology Act 2000.\n\nDisputes shall first be attempted to be resolved through good-faith communication with Kechi. If unresolved, disputes shall be subject to the jurisdiction of the courts having appropriate jurisdiction over Kechi's registered place of business in NCR, India.",
            ),

            _buildSection(
              number: "18",
              title: "Contact Us",
              content:
                  "For questions, complaints, or support related to these Terms or any order, please contact us:\n\n• Entity: Kechi Posters\n• Email: support.kechi@gmail.com\n• Contact / WhatsApp: +91 9520266789\n• Operating Hours: Monday to Saturday, 10:00 AM – 7:00 PM IST\n\nWe aim to respond to all queries within 2 business days.",
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
