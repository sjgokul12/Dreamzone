import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 9 New E-Government Services for Karnataka Portals
final List<Map<String, dynamic>> eGovernmentServicesList = [
  {
    'id': 'egov_nadakacheri',
    'name': 'Nadakacheri',
    'category': 'E-Government',
    'asset_image': 'assets/Nadakacheri.png',
    'url': 'https://ajsk.karnataka.gov.in/nk5_online/Login/Login_Public',
    'color': '#0284C7',
    'desc': 'Certificate verification & public services',
  },
  {
    'id': 'egov_rtc',
    'name': 'RTC MR',
    'category': 'E-Government',
    'asset_image': 'assets/RTC MR.png',
    'url': 'https://landrecords.karnataka.gov.in/service2/RTC.aspx',
    'icon': 'landscape',
    'color': '#059669',
    'desc': 'View land records & RTC Pahani details',
  },
  {
    'id': 'egov_kaveri',
    'name': 'Kaveri',
    'category': 'E-Government',
    'asset_image': 'assets/Kaveri.png',
    'url': 'https://kaveri.karnataka.gov.in/landing-page',
    'icon': 'account_balance',
    'color': '#D97706',
    'desc': 'Property registration & stamp duty portal',
  },
  {
    'id': 'egov_ktown',
    'name': 'K Two Challen',
    'category': 'E-Government',
    'asset_image': 'assets/K Town.png',
    'url': 'https://k2.karnataka.gov.in/K2/',
    'icon': 'receipt_long',
    'color': '#7C3AED',
    'desc': 'Integrated financial management system',
  },
  {
    'id': 'egov_eswathu',
    'name': 'Eswathu',
    'category': 'E-Government',
    'asset_image': 'assets/Eswathu.png',
    'url': 'https://eswathu.karnataka.gov.in/',
    'icon': 'home_work',
    'color': '#2563EB',
    'desc': 'Gram Panchayat property documentation',
  },
  {
    'id': 'egov_sakala',
    'name': 'Sakala',
    'category': 'E-Government',
    'asset_image': 'assets/Sakala.png',
    'url': 'https://www.sakala.kar.nic.in/Index.aspx',
    'icon': 'verified_user',
    'color': '#DC2626',
    'desc': 'Timely delivery of citizen services',
  },
  {
    'id': 'egov_bbmp',
    'name': 'BBMP',
    'category': 'E-Government',
    'asset_image': 'assets/BBMP.png',
    'url': 'https://bbmptax.karnataka.gov.in/Default.aspx',
    'icon': 'apartment',
    'color': '#0891B2',
    'desc': 'Bengaluru BBMP property tax payment',
  },
  {
    'id': 'egov_landbuild',
    'name': 'Land Buld Aprv',
    'category': 'E-Government',
    'asset_image': 'assets/Land Build.png',
    'url':
        'https://bhu-yojane.karnataka.gov.in/Nirmana2/Login.aspx?q3t=0Jw64hzzl0YbfevQTIC3lhN6TRIrFX/hyF9Odi7JVS1PblX/RFg3x8WJg/dJeBAg',
    'icon': 'domain',
    'color': '#16A34A',
    'desc': 'Nirmana 2.0 land development portal',
  },
  {
    'id': 'egov_panchayat',
    'name': 'Panchayat',
    'category': 'E-Government',
    'asset_image': 'assets/Panchayat Tax.png',
    'url': 'https://bsk.karnataka.gov.in/BSK/csLogin/loginPage',
    'icon': 'foundation',
    'color': '#EA580C',
    'desc': 'Bapuji Seva Kendra GP tax portal',
  },
  {
    'id': 'egov_jalanidhi',
    'name': 'Jalanidhi',
    'category': 'E-Government',
    'asset_image': 'assets/Jalanidhi.png',
    'url': 'http://www.mrc.gov.in/jalanidhi/',
    'color': '#0284C7',
    'desc': 'Water connection portal',
  },
  {
    'id': 'egov_tn_urban_tax',
    'name': 'TN Urban Tax',
    'category': 'E-Government',
    'asset_image': 'assets/TN Urban Tax.png',
    'url': 'https://tnurbanepay.tn.gov.in/',
    'color': '#2563EB',
    'desc': 'Tamil Nadu urban e-pay portal',
  },
  {
    'id': 'egov_chennai_corp',
    'name': 'Chennai Corp',
    'category': 'E-Government',
    'asset_image': 'assets/Chennai Corp.png',
    'url': 'https://chennaicorporation.gov.in/gcc/',
    'color': '#059669',
    'desc': 'Greater Chennai Corporation',
  },
  {
    'id': 'egov_tn_govt',
    'name': 'TN GOVT',
    'category': 'E-Government',
    'asset_image': 'assets/TN GOVT.png',
    'url': 'https://www.tn.gov.in/index.php',
    'color': '#D97706',
    'desc': 'Tamil Nadu government portal',
  },
  {
    'id': 'egov_tn_land_survey',
    'name': 'TN Land Survey',
    'category': 'E-Government',
    'asset_image': 'assets/TN Land Survey.png',
    'url': 'https://tnlandsurvey.tn.gov.in/',
    'color': '#7C3AED',
    'desc': 'Tamil Nadu land survey portal',
  },
  {
    'id': 'egov_revenu',
    'name': 'Revenu',
    'category': 'E-Government',
    'asset_image': 'assets/Revenu.png',
    'url': 'https://revenue.kerala.gov.in/',
    'color': '#DC2626',
    'desc': 'Kerala revenue department',
  },
  {
    'id': 'egov_kerala_bhoomi',
    'name': 'Kerala Bhoomi',
    'category': 'E-Government',
    'asset_image': 'assets/Kerala Bhoomi.png',
    'url': 'https://entebhoomi.kerala.gov.in/web/home',
    'color': '#0891B2',
    'desc': 'Ente Bhoomi land records',
  },
  {
    'id': 'egov_kerala_lottery',
    'name': 'Kerala Lottery',
    'category': 'E-Government',
    'asset_image': 'assets/Kerala Lottery.png',
    'url': 'https://statelottery.kerala.gov.in/',
    'color': '#16A34A',
    'desc': 'Kerala state lottery portal',
  },
  {
    'id': 'egov_meesav_telan',
    'name': 'Meesav Telan',
    'category': 'E-Government',
    'asset_image': 'assets/Meesav Telan.png',
    'url': 'https://ts.meeseva.telangana.gov.in/meeseva/home.htm',
    'color': '#EA580C',
    'desc': 'Telangana MeeSeva portal',
  },
  {
    'id': 'egov_ssp',
    'name': 'SSP',
    'category': 'E-Government',
    'asset_image': 'assets/SSP.png',
    'url': 'https://ssp.postmatric.karnataka.gov.in/HomePage.aspx',
    'color': '#2563EB',
    'desc': 'State Scholarship Portal Karnataka',
  },
  {
    'id': 'egov_nps',
    'name': 'NPS',
    'category': 'E-Government',
    'asset_image': 'assets/NPS.png',
    'url': 'https://scholarships.gov.in/ApplicationForm/login',
    'color': '#059669',
    'desc': 'National Scholarship Portal',
  },
  {
    'id': 'egov_tn_scholarship',
    'name': 'TN Scholarship',
    'category': 'E-Government',
    'asset_image': 'assets/TN Scholarship.png',
    'url': 'https://ssp24-25.tnega.org/institute/dashboard.html?details=undefined',
    'color': '#D97706',
    'desc': 'Tamil Nadu scholarship portal',
  },
  {
    'id': 'egov_whitehope',
    'name': 'Whitehope',
    'category': 'E-Government',
    'asset_image': 'assets/Whitehope.png',
    'url': 'https://www.whitehopefoundation.org/scholarship.html',
    'color': '#7C3AED',
    'desc': 'Whitehope scholarship foundation',
  },
  {
    'id': 'egov_kerala_state',
    'name': 'Kerala State',
    'category': 'E-Government',
    'asset_image': 'assets/Kerala State.png',
    'url': 'https://highereducation.kerala.gov.in/index.php/academic/scholarships',
    'color': '#DC2626',
    'desc': 'Kerala higher education scholarships',
  },
  {
    'id': 'egov_ap_schlor',
    'name': 'AP Schlor',
    'category': 'E-Government',
    'asset_image': 'assets/AP Schlor.png',
    'url': 'https://jnanabhumi.ap.gov.in/',
    'color': '#0891B2',
    'desc': 'JnanaBhumi AP scholarship portal',
  },
  {
    'id': 'egov_scholarship',
    'name': 'scholarship',
    'category': 'E-Government',
    'asset_image': 'assets/scholarship.png',
    'url': 'https://www.vidyadhan.org/web/index.php',
    'color': '#16A34A',
    'desc': 'Vidyadhan scholarship portal',
  },
  {
    'id': 'egov_sc_st',
    'name': 'SC ST',
    'category': 'E-Government',
    'asset_image': 'assets/SC ST.png',
    'url': 'https://swdservices.karnataka.gov.in/SWPRIZEMONEY/',
    'color': '#EA580C',
    'desc': 'Karnataka SC ST prize money portal',
  },
  {
    'id': 'egov_sc_st_kerala',
    'name': 'Sc St Kerala',
    'category': 'E-Government',
    'asset_image': 'assets/Sc St Kerala.png',
    'url': 'https://scdd.kerala.gov.in/index.php/schemes',
    'color': '#2563EB',
    'desc': 'Kerala SC ST development schemes',
  },
  {
    'id': 'egov_sc_st_tn',
    'name': 'Sc st TN',
    'category': 'E-Government',
    'asset_image': 'assets/Sc st TN.png',
    'url': 'https://www.tntribalwelfare.tn.gov.in/',
    'color': '#059669',
    'desc': 'TN Tribal welfare portal',
  },
  {
    'id': 'egov_edu_loan',
    'name': 'Edu Loan',
    'category': 'E-Government',
    'asset_image': 'assets/Edu Loan.png',
    'url': 'https://pmvidyalaxmi.co.in/',
    'color': '#D97706',
    'desc': 'PM Vidya Laxmi education loan',
  },
  {
    'id': 'egov_traffic_payment',
    'name': 'Traffic Payment',
    'category': 'E-Government',
    'asset_image': 'assets/Traffic Payment.png',
    'url': 'https://kspapp.ksp.gov.in/ksp/api/traffic-challan',
    'color': '#DC2626',
    'desc': 'KSP traffic challan payment',
  },
];

/// Helper function to launch official government portal link directly
Future<void> launchEGovPortal(String urlStr) async {
  final clean = urlStr.trim();
  if (clean.isEmpty) return;
  final uri = Uri.parse(clean);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (_) {
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {}
  }
}

/// Standalone Responsive E-Government Services Screen
class EGovernmentServicesScreen extends StatelessWidget {
  const EGovernmentServicesScreen({super.key});

  static const Color primaryTeal = Color(0xFF00A896);
  static const Color headerNavy = Color(0xFF028090);
  static const Color bgCream = Color(0xFFF4FBF7);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    // Media Query for Responsive Grid Column Layout
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    int crossAxisCount = 3;
    if (screenWidth > 1100) {
      crossAxisCount = 5;
    } else if (screenWidth > 800) {
      crossAxisCount = 4;
    } else if (screenWidth < 400) {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: primaryTeal,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'E-Government Services',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C9A7), primaryTeal, headerNavy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withAlpha(80),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Karnataka E-Governance Portals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Direct access to official government services & land records',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Responsive Services Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: screenWidth > 600 ? 0.85 : 0.78,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: eGovernmentServicesList.length,
                itemBuilder: (context, index) {
                  final service = eGovernmentServicesList[index];
                  final name = service['name'].toString();
                  final assetImg = service['asset_image'].toString();
                  final url = service['url'].toString();

                  return GestureDetector(
                    onTap: () => launchEGovPortal(url),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardWhite,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: primaryTeal.withAlpha(40),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryTeal.withAlpha(20),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Image.asset(
                              assetImg,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.assured_workload_rounded,
                                color: primaryTeal,
                                size: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
