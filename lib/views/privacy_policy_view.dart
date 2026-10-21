import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

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
          "Privacy Policy",
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
                        child: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF8B0000), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Kechi Privacy Policy",
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
                    "Kechi (\"we\", \"us\", or \"our\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, store, share, and protect your personal information when you use the Kechi mobile application, website, and services (\"Platform\").\n\nBy using Kechi, you agree to the collection and use of your information in accordance with this Privacy Policy. This Policy forms part of our Terms & Conditions.\n\nThis Privacy Policy is published in compliance with the Information Technology Act, 2000, the Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011, and the Digital Personal Data Protection Act, 2023, as applicable.",
                    style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              number: "1",
              title: "Who We Are",
              content:
                  "Kechi is a poster-selling platform based in Ghaziabad, National Capital Region (NCR), India. We sell printed posters in A3, A4, and A5 sizes and, where available, offer customised poster creation services.\n\nIf you have any questions about this Privacy Policy or how we handle your data, please contact us at:\n• Entity: Kechi\n• Email: support.kechi@gmail.com\n• WhatsApp / Phone: +91 9520266789\n• Studio Address: Mahagunpuram, Ghaziabad, Uttar Pradesh - 201015\n• Registered Office Address: 7 Acheetpur Udideeh, PO - Uri Ka Deeh, Pratapgarh, Uttar Pradesh - 230402",
            ),

            _buildSection(
              number: "2",
              title: "What Data We Collect",
              content:
                  "We collect the following categories of personal information:\n\na) Information You Provide Directly:\n• Full name\n• Delivery address (including PIN code)\n• Mobile phone number\n• Email address (if provided)\n• Order details (items, sizes, quantities)\n• Payment method and transaction references (not card/bank details — see Section 5)\n• WhatsApp messages sent to us for order confirmation or support\n• Photographs or other content uploaded for custom poster creation\n\nb) Information Collected Automatically:\n• Device type and operating system\n• IP address and approximate location (city-level only)\n\nc) Information From Third Parties:\n• Payment confirmation and transaction status from payment providers (e.g. Razorpay)\n• Delivery status and proof-of-delivery photographs from courier partners (e.g. Shadowfax, Bombax, Borzo)",
            ),

            _buildSection(
              number: "3",
              title: "How We Use Your Data",
              content:
                  "We use your personal information only for the following purposes:\n• To process and fulfil your orders, including printing and delivery coordination\n• To confirm orders via WhatsApp or other written channels\n• To communicate order status, delivery updates, and support responses\n• To process payments through our payment provider\n• To handle returns, cancellations, and refund requests\n• To improve the Platform — including fixing bugs, improving features, and understanding usage patterns\n• To maintain records as required by applicable law\n• To send you updates about new collections or offers (only if you have opted in — you may opt out at any time)\n\nWe do not use your personal data for automated decision-making or profiling.",
            ),

            _buildSection(
              number: "4",
              title: "Custom Poster Content",
              content:
                  "If you upload photographs or other content for a custom poster, we use that content solely to print and fulfil your order. We do not use uploaded content for marketing, training, or any other purpose without your explicit consent.\n\nUploaded content is stored temporarily for order processing and deleted after the order is fulfilled, unless you request otherwise or unless retention is required for dispute resolution.\n\nBy uploading content, you confirm that you have the right to use and reproduce it. You are solely responsible for the content you upload. Please refer to Section 5 of our Terms & Conditions for full details on prohibited content.",
            ),

            _buildSection(
              number: "5",
              title: "Payments & Financial Data",
              content:
                  "Kechi does not collect, process, or store your credit card numbers, debit card numbers, CVV, UPI PIN, OTP, net banking passwords, or any other complete payment credentials.\n\nPrepaid payments are processed entirely by our third-party payment provider (currently Razorpay). Your payment information is subject to Razorpay's own privacy policy and security practices. We only receive a transaction reference number and payment status confirmation.\n\nFor Cash on Delivery (COD) orders, the only financial information we hold is the order value and confirmation of cash collected by our courier partner.",
            ),

            _buildSection(
              number: "6",
              title: "How We Share Your Data",
              content:
                  "We do not sell, rent, or trade your personal data to any third party. We share your information only in the following limited circumstances:\n\n• Courier Partners: We share your name, delivery address, and phone number with our courier partners (e.g. Shadowfax, Bombax, Borzo) solely for the purpose of delivering your order. Courier partners may collect proof-of-delivery photographs on our behalf.\n\n• Payment Providers: We share the minimum information necessary (order value, contact reference) with our payment provider (Razorpay) to process your transaction.\n\n• Printing Partners: We share your order details (poster specifications, design files) with our printing partner solely for order fulfilment. We do not share your personal contact or delivery details with the printer.\n\n• Legal Requirements: We may disclose your information to law enforcement or regulatory authorities if required by applicable law, court order, or government request.\n\nAll third parties we work with are required to handle your data securely and only for the purpose for which it was shared.",
            ),

            _buildSection(
              number: "7",
              title: "Data Retention",
              content:
                  "We retain your personal data only for as long as necessary to fulfil the purpose for which it was collected, or as required by law. Specifically:\n• Order information (name, address, order details) — retained for a minimum of 3 years for accounting and dispute resolution purposes\n• WhatsApp conversation records — retained for 12 months from the date of the last message\n• Custom poster upload content — deleted after order fulfilment, unless required for an active dispute\n• Payment transaction references — retained for 5 years as required under Indian financial recordkeeping rules\n\nWhen data is no longer required, we delete or anonymise it securely.",
            ),

            _buildSection(
              number: "8",
              title: "Your Rights & Account Deletion",
              content:
                  "Under applicable Indian law, including the Digital Personal Data Protection Act 2023, you have the right to access, correct, or request the deletion of your personal data and account.\n\n• Account & Data Deletion:\nIf you wish to delete your Kechi account and all associated personal data (including profile details, saved addresses, cart items, order history, and wishlist), you can request deletion anytime by contacting our support team:\n  - Email: support.kechi@gmail.com\n  - Phone / WhatsApp: +91 9520266789\n\nUpon receiving your request, our support team will verify your account and permanently remove your account and all associated personal records within 3 to 5 business days, except for any transactional invoices required to be retained for statutory tax and accounting compliances.\n\n• Other Rights:\nYou may also request a copy of the data we hold about you, request corrections to inaccurate details, or withdraw consent for marketing messages by contacting our support team.",
            ),

            _buildSection(
              number: "9",
              title: "Data Security",
              content:
                  "We take reasonable technical and organisational measures to protect your personal data from unauthorised access, loss, misuse, or disclosure. These include:\n• Secure storage of order and customer data\n• Limiting access to personal data to only those who need it for order fulfilment\n• Use of third-party payment processors that are PCI-DSS compliant\n• Not requesting or storing complete payment credentials under any circumstances\n\nHowever, no method of transmission over the internet or electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your data, we cannot guarantee absolute security.\n\nIf you suspect that your account or personal data has been compromised, please contact us immediately at support.kechi@gmail.com.",
            ),

            _buildSection(
              number: "10",
              title: "Children's Privacy",
              content:
                  "Kechi is intended for users aged 16 and above. Users between 16 and 18 years of age must have the consent of a parent or legal guardian.\n\nWe do not knowingly collect personal data from children under the age of 16. If we become aware that a child under 16 has provided us with personal information without verifiable parental consent, we will delete that information promptly. If you believe a child has provided us with their data, please contact us at support.kechi@gmail.com.",
            ),

            _buildSection(
              number: "11",
              title: "Third-Party Links & Services",
              content:
                  "The Kechi Platform may contain links to third-party websites or integrate with third-party services (such as payment gateways or social media platforms). This Privacy Policy does not apply to those third-party services. We encourage you to review the privacy policies of any third-party services you use.",
            ),

            _buildSection(
              number: "12",
              title: "Changes to This Privacy Policy",
              content:
                  "We may update this Privacy Policy from time to time to reflect changes in our practices, the Platform, or applicable law. Updated versions will be published on the Platform with a revised \"Last Updated\" date.\n\nYour continued use of Kechi after a revised Privacy Policy is published constitutes your acceptance of the updated Policy. We encourage you to review this Policy periodically.\n\nFor significant changes that affect how we use your data, we will notify you directly via WhatsApp or the app where reasonably practicable.",
            ),

            _buildSection(
              number: "13",
              title: "Grievance Officer",
              content:
                  "In accordance with the Information Technology Act, 2000 and applicable rules, the contact details of the Grievance Officer are as follows:\n\n• Designation: Grievance Officer, Kechi\n• Email: support.kechi@gmail.com\n• Phone / WhatsApp: +91 9520266789\n• Studio Address: Mahagunpuram, Ghaziabad, Uttar Pradesh - 201015\n• Registered Office Address: 7 Acheetpur Udideeh, PO - Uri Ka Deeh, Pratapgarh, Uttar Pradesh - 230402\n\nThe Grievance Officer can be contacted for any complaints or concerns regarding the processing of your personal data. We will acknowledge your complaint within 48 hours and resolve it within 30 days.",
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
