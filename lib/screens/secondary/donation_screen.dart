import 'package:ccet_alumini_app/screens/secondary/club_detail_screen.dart';
import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  late Future<List<dynamic>> _campaignsFuture;
  late Future<List<dynamic>> _myDonationsFuture;

  @override
  void initState() {
    super.initState();
    _campaignsFuture = ApiService.getCampaigns();
    _refreshDonations();
  }

  void _refreshDonations() {
    final user = AuthService().currentUser;
    if (user != null) {
      setState(() {
        _myDonationsFuture = ApiService.getMyDonations(user.uid);
      });
    } else {
      _myDonationsFuture = Future.value([]);
    }
  }

  Future<void> _makeDonation(String campaignTitle) async {
    final amountController = TextEditingController();
    final messageController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Donate to $campaignTitle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (INR)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty) return;

              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;

              Navigator.pop(context); // Close dialog

              try {
                await ApiService.donate({
                  'donorId': AuthService().currentUser!.uid,
                  'amount': amount,
                  'campaign': campaignTitle,
                  'message': messageController.text,
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you for your donation!'),
                    ),
                  );
                  _refreshDonations();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Donation failed: $e')),
                  );
                }
              }
            },
            child: const Text('Donate'),
          ),
        ],
      ),
    );
  }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(context),
            const SizedBox(height: 24),
            const AutoSizeText(
              'Active Campaigns',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<dynamic>>(
              future: _campaignsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError)
                  return const Text('Error loading campaigns');

                final campaigns = snapshot.data ?? [];
                return Column(
                  children: campaigns
                      .map((c) => _buildCampaignTile(c))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 24),
            const AutoSizeText(
              'College Clubs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            _buildClubGrid(context),

            const SizedBox(height: 24),
            const AutoSizeText(
              'My Donation History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<dynamic>>(
              future: _myDonationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final donations = snapshot.data ?? [];
                if (donations.isEmpty) {
                  return const Text(
                    'No donations yet. Start making a difference!',
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: donations.length,
                  itemBuilder: (context, index) {
                    final donation = donations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          child: Text(
                            '₹',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        title: Text(donation['campaign'] ?? 'Donation'),
                        subtitle: Text(
                          DateFormat.yMMMd().format(
                            DateTime.parse(donation['date']),
                          ),
                        ),
                        trailing: Text(
                          '₹${donation['amount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            const Icon(Icons.volunteer_activism, size: 50, color: Colors.white),
            const SizedBox(height: 16),
            AutoSizeText(
              'Support Your Alma Mater',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
              onPressed: () {
                // Scroll to campaigns or show a general donate dialog
                _makeDonation('General Fund');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: const AutoSizeText('Donate Now', maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubGrid(BuildContext context) {
    final clubs = [
      {
        'name': 'NSS',
        'desc':
            'Not Me But You. Empowering youth through social service and community development.',
        'color': Colors.blue.shade700,
        'icon': Icons.volunteer_activism,
      },
      {
        'name': 'LEO Club',
        'desc':
            'Leadership, Experience, Opportunity. Developing young leaders through service.',
        'color': Colors.orange.shade800,
        'icon': Icons.star,
      },
      {
        'name': 'Rotary Club',
        'desc':
            'Service Above Self. Connecting world leaders to tackle humanity\'s challenges.',
        'color': Colors.indigo.shade900,
        'icon': Icons.public,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: clubs.length,
      itemBuilder: (context, index) {
        final club = clubs[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClubDetailScreen(
                  clubName: club['name'] as String,
                  description: club['desc'] as String,
                  themeColor: club['color'] as Color,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: (club['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (club['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  club['icon'] as IconData,
                  color: club['color'] as Color,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  club['name'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: club['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCampaignTile(dynamic campaign) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.campaign, color: Colors.orange),
        title: Text(
          campaign['title'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(campaign['description'] ?? ''),
        trailing: ElevatedButton(
          onPressed: () => _makeDonation(campaign['title']),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Donate'),
        ),
      ),
    );
  }
}
