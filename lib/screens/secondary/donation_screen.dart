import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AutoSizeText('Donations & Contributions', maxLines: 1),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.volunteer_activism,
                      size: 50,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    AutoSizeText(
                      'Support Your Alma Mater',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    const AutoSizeText(
                      'Your contributions help us build a better future for the next generation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const AutoSizeText('Donate Now', maxLines: 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const AutoSizeText(
              'Active Campaigns',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            _buildCampaignTile('Scholarship Fund 2024'),
            _buildCampaignTile('Infrastructure Development'),
            _buildCampaignTile('Alumni Events Fund'),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignTile(String title) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.campaign),
        title: AutoSizeText(title, maxLines: 1),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
