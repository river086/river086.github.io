class Profession {
  final String id;
  final String title;
  final int minSalary;
  final int maxSalary;
  final double raise;
  final StudentLoan studentLoan;
  final FixedCosts fixedCosts;

  Profession({
    required this.id,
    required this.title,
    required this.minSalary,
    required this.maxSalary,
    required this.raise,
    required this.studentLoan,
    required this.fixedCosts,
  });

  factory Profession.fromMap(Map<String, dynamic> map) {
    return Profession(
      id: map['id'],
      title: map['title'],
      minSalary: map['salaryRange']['min'],
      maxSalary: map['salaryRange']['max'],
      raise: map['raise'],
      studentLoan: StudentLoan.fromMap(map['studentLoan']),
      fixedCosts: FixedCosts.fromMap(map['fixedCosts']),
    );
  }
}

class StudentLoan {
  final double principal;
  final double annualRate;
  final int termMonths;

  StudentLoan({
    required this.principal,
    required this.annualRate,
    required this.termMonths,
  });

  factory StudentLoan.fromMap(Map<String, dynamic> map) {
    return StudentLoan(
      principal: map['principal'].toDouble(),
      annualRate: map['annualRate'].toDouble(),
      termMonths: map['termMonths'],
    );
  }
}

class FixedCosts {
  final double food;
  final double housing;

  FixedCosts({
    required this.food,
    required this.housing,
  });

  factory FixedCosts.fromMap(Map<String, dynamic> map) {
    return FixedCosts(
      food: map['food'].toDouble(),
      housing: map['housing'].toDouble(),
    );
  }
}