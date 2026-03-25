import { db } from '../firebase';
import { collection, addDoc, getDocs, query, where } from 'firebase/firestore';
import { type Problem } from './githubService';

export interface CustomProblem extends Problem {
  content: string;
  sampleTestCase: string;
  exampleTestcases: string;
}

export const saveCustomProblem = async (problem: Omit<CustomProblem, 'id'>) => {
  try {
    const docRef = await addDoc(collection(db, "problems"), {
      ...problem,
      createdAt: new Date().toISOString()
    });
    return docRef.id;
  } catch (error) {
    console.error("Error saving custom problem:", error);
    throw error;
  }
};

export const fetchCustomCompanies = async (): Promise<string[]> => {
  try {
    const snap = await getDocs(collection(db, "problems"));
    const companies = new Set<string>();
    snap.docs.forEach(doc => {
      const data = doc.data();
      if (data.company) companies.add(data.company);
    });
    return Array.from(companies);
  } catch (error) {
    console.error("Error fetching custom companies:", error);
    return [];
  }
};

export const fetchCustomProblemsByCompany = async (company: string): Promise<CustomProblem[]> => {
  try {
    const q = query(collection(db, "problems"), where("company", "==", company));
    const snap = await getDocs(q);
    return snap.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    })) as CustomProblem[];
  } catch (error) {
    console.error(`Error fetching problems for ${company}:`, error);
    return [];
  }
};
export const deleteCustomCompany = async (company: string): Promise<void> => {
  try {
    const q = query(collection(db, "problems"), where("company", "==", company));
    const snap = await getDocs(q);
    const { writeBatch } = await import('firebase/firestore');
    const batch = writeBatch(db);
    snap.docs.forEach(d => {
      batch.delete(d.ref);
    });
    await batch.commit();
  } catch (error) {
    console.error(`Error deleting company ${company}:`, error);
    throw error;
  }
};
