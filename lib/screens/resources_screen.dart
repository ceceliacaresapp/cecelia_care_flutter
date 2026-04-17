import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart'; // Corrected import path

class ResourceInfo {
  final String title;
  final String subtitle;
  final String url;

  ResourceInfo({
    required this.title,
    required this.subtitle,
    required this.url,
  });
}

class ResourcesScreen extends StatelessWidget {
  ResourcesScreen({super.key});

  // ADD THE NEW RESOURCES TO THIS LIST
  final List<ResourceInfo> _resources = [
    // Existing Resources
    ResourceInfo(title: 'Alzheimer\'s Association', subtitle: 'Information and support for Alzheimer\'s disease.', url: 'https://www.alz.org'),
    ResourceInfo(title: 'AARP Family Caregiving', subtitle: 'Resources for family caregivers.', url: 'https://www.aarp.org/caregiving/'),
    ResourceInfo(title: 'National Institute on Aging', subtitle: 'Health information for older adults.', url: 'https://www.nia.nih.gov'),
    ResourceInfo(title: 'Family Caregiver Alliance', subtitle: 'Services for family caregivers of adults with chronic conditions.', url: 'https://www.caregiver.org'),
    ResourceInfo(title: 'Medicare.gov', subtitle: 'Official U.S. government site for Medicare.', url: 'https://www.medicare.gov'),
    ResourceInfo(title: 'Eldercare Locator', subtitle: 'Connects to services for older adults and their families.', url: 'https://eldercare.acl.gov'),
    ResourceInfo(title: 'National Council on Aging', subtitle: 'Improving the lives of older Americans.', url: 'https://www.ncoa.org'),
    ResourceInfo(title: 'Caregiver Action Network', subtitle: 'Education, peer support, and resources for family caregivers.', url: 'https://caregiveraction.org/'),
    ResourceInfo(title: 'American Heart Association', subtitle: 'Information on heart health and stroke.', url: 'https://www.heart.org'),
    ResourceInfo(title: 'American Diabetes Association', subtitle: 'Resources for diabetes management and prevention.', url: 'https://www.diabetes.org'),
    ResourceInfo(title: 'Arthritis Foundation', subtitle: 'Information and support for arthritis.', url: 'https://www.arthritis.org'),
    ResourceInfo(title: 'National Osteoporosis Foundation', subtitle: 'Information on bone health and osteoporosis.', url: 'https://www.nof.org'),
    ResourceInfo(title: 'Parkinson\'s Foundation', subtitle: 'Resources for people with Parkinson\'s and their families.', url: 'https://www.parkinson.org'),
    ResourceInfo(title: 'American Lung Association', subtitle: 'Information on lung health.', url: 'https://www.lung.org'),
    ResourceInfo(title: 'National Kidney Foundation', subtitle: 'Information on kidney disease.', url: 'https://www.kidney.org'),
    ResourceInfo(title: 'Mental Health America', subtitle: 'Resources for mental health.', url: 'https://www.mhanational.org'),
    ResourceInfo(title: 'Substance Abuse and Mental Health Services Administration (SAMHSA)', subtitle: 'Behavioral health resources.', url: 'https://www.samhsa.gov'),
    ResourceInfo(title: 'VA Caregiver Support', subtitle: 'Support for caregivers of Veterans.', url: 'https://www.caregiver.va.gov'),
    ResourceInfo(title: 'Social Security Administration', subtitle: 'Information on retirement, disability, and survivors benefits.', url: 'https://www.ssa.gov'),

    // ADD NEW LGBTQ+ AFFIRMING LEGAL RESOURCES HERE:
    ResourceInfo(
      title: 'SAGE (Advocacy & Services for LGBT Elders)',
      subtitle: 'Legal resources and advocacy for LGBTQ+ elders. Provides referrals to elder law attorneys nationwide.',
      url: 'https://www.sageusa.org/what-we-do/legal/',
    ),
    ResourceInfo(
      title: 'Lambda Legal (LGBTQ+ Rights)',
      subtitle: 'Works to achieve full recognition of the civil rights of lesbians, gay men, bisexuals, transgender people, and people with HIV through impact litigation, education, and public policy work.',
      url: 'https://www.lambdalegal.org/issues/elder-law',
    ),
    ResourceInfo(
      title: 'National Center for Lesbian Rights (NCLR)',
      subtitle: 'Offers legal assistance and advice, including resources on elder law, family law, and estate planning for LGBTQ+ individuals.',
      url: 'https://www.nclrights.org/issue/elder-law/',
    ),
    ResourceInfo(
      title: 'Transgender Law Center (TLC)',
      subtitle: 'The largest national trans-led organization advocating for a world in which all people are free to define themselves and their futures. Provides legal information and support.',
      url: 'https://transgenderlawcenter.org/resources', // Look for legal resources here
    ),
    ResourceInfo(
      title: 'GLAD (GLBTQ Legal Advocates & Defenders)',
      subtitle: 'Offers legal advocacy and public education for the LGBTQ+ community, including elder law issues.',
      url: 'https://www.glad.org/know-your-rights/aging/',
    ),
    // Add more resources as needed, following the same format.
  ];

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Use AppLocalizations for snackbar message
      final l10n = AppLocalizations.of(context)!;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotLaunchUrl(urlString))), // Add this string to your arb file
        );
      }
    }
  }

  Widget _buildResourceButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String url,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16.0),
          backgroundColor: Theme.of(context).colorScheme.surface, // Use theme color
          foregroundColor: Theme.of(context).colorScheme.onSurface, // Use theme color for text
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          elevation: 2,
        ),
        onPressed: () => _launchURL(context, url),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.open_in_new,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Access localization
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpfulResourcesTitle), // Use localized title
      ),
      body: ListView.builder(
        itemCount: _resources.length,
        itemBuilder: (context, index) {
          final resource = _resources[index];
          return _buildResourceButton(
            context,
            title: resource.title,
            subtitle: resource.subtitle,
            url: resource.url,
          );
        },
      ),
    );
  }
}