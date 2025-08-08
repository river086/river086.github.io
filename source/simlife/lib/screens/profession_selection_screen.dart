import 'package:flutter/material.dart';
import '../models/profession.dart';
import 'game_screen.dart';

class ProfessionSelectionScreen extends StatefulWidget {
  const ProfessionSelectionScreen({super.key});

  @override
  State<ProfessionSelectionScreen> createState() => _ProfessionSelectionScreenState();
}

class _ProfessionSelectionScreenState extends State<ProfessionSelectionScreen> {
  String? selectedProfessionId;
  
  // All 32 professions from SimLifeGame XML data to match BDD specification
  final List<Profession> professions = [
    // Entry-Level / Service
    Profession(
      id: 'fast_food_worker',
      title: 'Fast-Food Worker',
      minSalary: 20000,
      maxSalary: 36000,
      raise: 0.04,
      studentLoan: StudentLoan(principal: 0, annualRate: 0.05, termMonths: 0),
      fixedCosts: FixedCosts(food: 600, housing: 1800),
    ),
    Profession(
      id: 'barista',
      title: 'Barista',
      minSalary: 21000,
      maxSalary: 38000,
      raise: 0.05,
      studentLoan: StudentLoan(principal: 0, annualRate: 0.05, termMonths: 0),
      fixedCosts: FixedCosts(food: 600, housing: 1800),
    ),
    Profession(
      id: 'retail_sales',
      title: 'Retail Sales Clerk',
      minSalary: 24000,
      maxSalary: 42000,
      raise: 0.05,
      studentLoan: StudentLoan(principal: 0, annualRate: 0.05, termMonths: 0),
      fixedCosts: FixedCosts(food: 600, housing: 1800),
    ),
    Profession(
      id: 'waiter',
      title: 'Restaurant Server',
      minSalary: 24000,
      maxSalary: 42000,
      raise: 0.07,
      studentLoan: StudentLoan(principal: 15000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 600, housing: 1800),
    ),
    Profession(
      id: 'customer_service_rep',
      title: 'Customer Service Rep',
      minSalary: 30000,
      maxSalary: 55000,
      raise: 0.06,
      studentLoan: StudentLoan(principal: 5000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 650, housing: 1900),
    ),
    Profession(
      id: 'administrative_assistant',
      title: 'Administrative Assistant',
      minSalary: 33000,
      maxSalary: 60000,
      raise: 0.06,
      studentLoan: StudentLoan(principal: 5000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 650, housing: 1900),
    ),
    Profession(
      id: 'construction_laborer',
      title: 'Construction Laborer',
      minSalary: 30000,
      maxSalary: 50000,
      raise: 0.05,
      studentLoan: StudentLoan(principal: 0, annualRate: 0.05, termMonths: 0),
      fixedCosts: FixedCosts(food: 650, housing: 1900),
    ),
    Profession(
      id: 'truck_driver',
      title: 'Truck Driver',
      minSalary: 42000,
      maxSalary: 70000,
      raise: 0.06,
      studentLoan: StudentLoan(principal: 7000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 650, housing: 1900),
    ),
    // Skilled Trades
    Profession(
      id: 'electrician',
      title: 'Electrician',
      minSalary: 45000,
      maxSalary: 80000,
      raise: 0.06,
      studentLoan: StudentLoan(principal: 10000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 700, housing: 2000),
    ),
    Profession(
      id: 'plumber',
      title: 'Plumber',
      minSalary: 43000,
      maxSalary: 77000,
      raise: 0.06,
      studentLoan: StudentLoan(principal: 10000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 700, housing: 2000),
    ),
    Profession(
      id: 'carpenter',
      title: 'Carpenter',
      minSalary: 38000,
      maxSalary: 70000,
      raise: 0.06,
      studentLoan: StudentLoan(principal: 5000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 700, housing: 2000),
    ),
    Profession(
      id: 'auto_mechanic',
      title: 'Automotive Technician',
      minSalary: 35000,
      maxSalary: 60000,
      raise: 0.06,
      studentLoan: StudentLoan(principal: 10000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 700, housing: 2000),
    ),
    // Culinary / Lifestyle
    Profession(
      id: 'chef',
      title: 'Chef',
      minSalary: 40000,
      maxSalary: 72000,
      raise: 0.07,
      studentLoan: StudentLoan(principal: 15000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 750, housing: 2100),
    ),
    Profession(
      id: 'fitness_trainer',
      title: 'Fitness Trainer',
      minSalary: 32000,
      maxSalary: 60000,
      raise: 0.08,
      studentLoan: StudentLoan(principal: 10000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 700, housing: 2000),
    ),
    // Creative / Media
    Profession(
      id: 'graphic_designer',
      title: 'Graphic Designer',
      minSalary: 38000,
      maxSalary: 80000,
      raise: 0.07,
      studentLoan: StudentLoan(principal: 20000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 750, housing: 2100),
    ),
    Profession(
      id: 'ux_designer',
      title: 'UX Designer',
      minSalary: 75000,
      maxSalary: 140000,
      raise: 0.08,
      studentLoan: StudentLoan(principal: 22000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 900, housing: 2400),
    ),
    Profession(
      id: 'journalist',
      title: 'Journalist',
      minSalary: 38000,
      maxSalary: 70000,
      raise: 0.06,
      studentLoan: StudentLoan(principal: 25000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 750, housing: 2100),
    ),
    Profession(
      id: 'content_creator',
      title: 'Content Creator',
      minSalary: 35000,
      maxSalary: 85000,
      raise: 0.20,
      studentLoan: StudentLoan(principal: 25000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 750, housing: 2100),
    ),
    // Business / Office
    Profession(
      id: 'marketing_specialist',
      title: 'Marketing Specialist',
      minSalary: 45000,
      maxSalary: 95000,
      raise: 0.07,
      studentLoan: StudentLoan(principal: 20000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 800, housing: 2200),
    ),
    Profession(
      id: 'sales_manager',
      title: 'Sales Manager',
      minSalary: 85000,
      maxSalary: 175000,
      raise: 0.10,
      studentLoan: StudentLoan(principal: 15000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 900, housing: 2400),
    ),
    Profession(
      id: 'accountant',
      title: 'Accountant',
      minSalary: 50000,
      maxSalary: 105000,
      raise: 0.07,
      studentLoan: StudentLoan(principal: 22000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 800, housing: 2200),
    ),
    Profession(
      id: 'financial_analyst',
      title: 'Financial Analyst',
      minSalary: 70000,
      maxSalary: 125000,
      raise: 0.08,
      studentLoan: StudentLoan(principal: 25000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 850, housing: 2300),
    ),
    // STEM / Tech
    Profession(
      id: 'software_dev',
      title: 'Software Developer',
      minSalary: 85000,
      maxSalary: 150000,
      raise: 0.08,
      studentLoan: StudentLoan(principal: 35000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 900, housing: 2400),
    ),
    Profession(
      id: 'data_scientist',
      title: 'Data Scientist',
      minSalary: 80000,
      maxSalary: 145000,
      raise: 0.10,
      studentLoan: StudentLoan(principal: 30000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 900, housing: 2400),
    ),
    // Education / Health / Safety
    Profession(
      id: 'teacher_elementary',
      title: 'Elementary Teacher',
      minSalary: 45000,
      maxSalary: 85000,
      raise: 0.05,
      studentLoan: StudentLoan(principal: 22000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 600, housing: 1800),
    ),
    Profession(
      id: 'registered_nurse',
      title: 'Registered Nurse',
      minSalary: 65000,
      maxSalary: 115000,
      raise: 0.06,
      studentLoan: StudentLoan(principal: 25000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 800, housing: 2200),
    ),
    Profession(
      id: 'paramedic',
      title: 'Paramedic',
      minSalary: 35000,
      maxSalary: 62000,
      raise: 0.06,
      studentLoan: StudentLoan(principal: 12000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 700, housing: 2000),
    ),
    Profession(
      id: 'police_officer',
      title: 'Police Officer',
      minSalary: 50000,
      maxSalary: 95000,
      raise: 0.06,
      studentLoan: StudentLoan(principal: 10000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 750, housing: 2100),
    ),
    Profession(
      id: 'firefighter',
      title: 'Firefighter',
      minSalary: 40000,
      maxSalary: 75000,
      raise: 0.06,
      studentLoan: StudentLoan(principal: 10000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 750, housing: 2100),
    ),
    // Real Estate / Sales
    Profession(
      id: 'real_estate_agent',
      title: 'Real Estate Agent',
      minSalary: 35000,
      maxSalary: 80000,
      raise: 0.08,
      studentLoan: StudentLoan(principal: 8000, annualRate: 0.05, termMonths: 120),
      fixedCosts: FixedCosts(food: 800, housing: 2200),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Career'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Select Your Starting Profession',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your choice will determine your starting salary, student loans, and fixed costs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: professions.length,
                    itemBuilder: (context, index) {
                      final profession = professions[index];
                      final isSelected = selectedProfessionId == profession.id;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isSelected ? 8 : 2,
                        color: isSelected ? Colors.blue[50] : null,
                        child: ListTile(
                          title: Text(
                            profession.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.blue[800] : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Salary: \$${profession.minSalary.toString().replaceAll(RegExp(r'(?=(?:\d{3})+$)'), ',')} - \$${profession.maxSalary.toString().replaceAll(RegExp(r'(?=(?:\d{3})+$)'), ',')}'),
                              Text('Student Loan: \$${profession.studentLoan.principal.toInt().toString().replaceAll(RegExp(r'(?=(?:\d{3})+$)'), ',')}'),
                              Text('Monthly Housing: \$${profession.fixedCosts.housing.toInt()}'),
                              Text('Annual Raise: ${(profession.raise * 100).toStringAsFixed(1)}%'),
                            ],
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? Colors.blue : Colors.grey[400],
                            child: Icon(
                              _getProfessionIcon(profession.id),
                              color: Colors.white,
                            ),
                          ),
                          trailing: isSelected 
                              ? const Icon(Icons.check_circle, color: Colors.blue)
                              : const Icon(Icons.radio_button_unchecked),
                          onTap: () {
                            setState(() {
                              selectedProfessionId = profession.id;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedProfessionId != null 
                        ? () => _startGame() 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF667eea),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Start Your Life!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getProfessionIcon(String professionId) {
    switch (professionId) {
      // Entry-Level / Service
      case 'fast_food_worker':
        return Icons.fastfood;
      case 'barista':
        return Icons.coffee;
      case 'retail_sales':
        return Icons.shopping_bag;
      case 'waiter':
        return Icons.restaurant;
      case 'customer_service_rep':
        return Icons.headset_mic;
      case 'administrative_assistant':
        return Icons.assignment;
      case 'construction_laborer':
        return Icons.construction;
      case 'truck_driver':
        return Icons.local_shipping;
      
      // Skilled Trades
      case 'electrician':
        return Icons.electrical_services;
      case 'plumber':
        return Icons.plumbing;
      case 'carpenter':
        return Icons.carpenter;
      case 'auto_mechanic':
        return Icons.car_repair;
      
      // Culinary / Lifestyle
      case 'chef':
        return Icons.restaurant_menu;
      case 'fitness_trainer':
        return Icons.fitness_center;
      
      // Creative / Media
      case 'graphic_designer':
        return Icons.design_services;
      case 'ux_designer':
        return Icons.web;
      case 'journalist':
        return Icons.article;
      case 'content_creator':
        return Icons.video_camera_back;
      
      // Business / Office
      case 'marketing_specialist':
        return Icons.campaign;
      case 'sales_manager':
        return Icons.trending_up;
      case 'accountant':
        return Icons.calculate;
      case 'financial_analyst':
        return Icons.analytics;
      
      // STEM / Tech
      case 'software_dev':
        return Icons.computer;
      case 'data_scientist':
        return Icons.science;
      
      // Education / Health / Safety
      case 'teacher_elementary':
        return Icons.school;
      case 'registered_nurse':
        return Icons.local_hospital;
      case 'paramedic':
        return Icons.medical_services;
      case 'police_officer':
        return Icons.local_police;
      case 'firefighter':
        return Icons.fire_truck;
      
      // Real Estate / Sales
      case 'real_estate_agent':
        return Icons.home;
      
      default:
        return Icons.work;
    }
  }

  void _startGame() {
    // Find the selected profession
    final selectedProfession = professions.firstWhere(
      (prof) => prof.id == selectedProfessionId,
    );
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameScreen(selectedProfession: selectedProfession),
      ),
    );
  }
}