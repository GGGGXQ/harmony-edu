export interface QaRecord {
  id: number;
  userId: number;
  courseId: number;
  question: string;
  answer: string;
  sources: string;
  createdAt: string;
}
