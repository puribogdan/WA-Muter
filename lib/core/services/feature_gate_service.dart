enum GateViolation {
  none,
  scheduleLimit,
  chatLimit,
}

class FeatureGateService {
  static const int freeMaxSchedules = 1;
  static const int freeMaxChatsPerSchedule = 1;

  const FeatureGateService();

  GateViolation canCreateSchedule({
    required bool isPremium,
    required int existingScheduleCount,
  }) {
    if (isPremium) return GateViolation.none;
    if (existingScheduleCount >= freeMaxSchedules) {
      return GateViolation.scheduleLimit;
    }
    return GateViolation.none;
  }

  GateViolation canSaveSchedule({
    required bool isPremium,
    required int existingScheduleCount,
    required bool isEditing,
    required int selectedChatsCount,
  }) {
    if (isPremium) return GateViolation.none;
    if (selectedChatsCount > freeMaxChatsPerSchedule) {
      return GateViolation.chatLimit;
    }
    if (!isEditing && existingScheduleCount >= freeMaxSchedules) {
      return GateViolation.scheduleLimit;
    }
    return GateViolation.none;
  }

  bool exceedsChatLimitForFree({
    required bool isPremium,
    required int selectedChatsCount,
  }) {
    if (isPremium) return false;
    return selectedChatsCount > freeMaxChatsPerSchedule;
  }
}

