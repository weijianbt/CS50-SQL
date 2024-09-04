import random
import datetime
from datetime import timedelta
from datetime import date
import csv
import pandas as pd

patient_ids = list(range(1,31))
patient_count = len(patient_ids)
doctor_ids = [1,3,5,7,9]
start_date = datetime.date(2024, 7, 1)
total_days = 120




diagnoses = [
    "Allergic Rhinitis",
    "Asthma",
    "Bronchitis",
    "Chronic Obstructive Pulmonary Disease (COPD)",
    "Pneumonia",
    "Gastroesophageal Reflux Disease (GERD)",
    "Peptic Ulcer Disease",
    "Irritable Bowel Syndrome (IBS)",
    "Constipation",
    "Diarrhea",
    "Hypertension",
    "Hypotension",
    "Diabetes Mellitus Type 1",
    "Diabetes Mellitus Type 2",
    "Hyperthyroidism",
    "Hypothyroidism",
    "Hyperlipidemia",
    "Coronary Artery Disease (CAD)",
    "Heart Failure",
    "Atrial Fibrillation",
    "Myocardial Infarction",
    "Stroke",
    "Migraine",
    "Tension Headache",
    "Cluster Headache",
    "Sinusitis",
    "Tonsillitis",
    "Pharyngitis",
    "Laryngitis",
    "Rhinovirus Infection",
    "Influenza",
    "Common Cold",
    "Chickenpox",
    "Measles",
    "Mumps",
    "Rubella",
    "Whooping Cough",
    "Tuberculosis",
    "Hepatitis A",
    "Hepatitis B",
    "Hepatitis C",
    "HIV/AIDS",
    "Herpes Simplex Virus (HSV)",
    "Human Papillomavirus (HPV)",
    "Psoriasis",
    "Eczema",
    "Acne",
    "Rosacea",
    "Dermatitis",
    "Contact Dermatitis",
    "Cellulitis",
    "Lupus",
    "Rheumatoid Arthritis",
    "Osteoarthritis",
    "Gout",
    "Fibromyalgia",
    "Chronic Fatigue Syndrome",
    "Back Pain",
    "Sciatica",
    "Carpal Tunnel Syndrome",
    "Cerebral Palsy",
    "Parkinson's Disease",
    "Multiple Sclerosis",
    "Epilepsy",
    "Seizure Disorder",
    "Alzheimer's Disease",
    "Dementia",
    "Anxiety Disorder",
    "Depression",
    "Bipolar Disorder",
    "Schizophrenia",
    "Post-Traumatic Stress Disorder (PTSD)",
    "Attention-Deficit/Hyperactivity Disorder (ADHD)",
    "Autism Spectrum Disorder",
    "Anorexia Nervosa",
    "Bulimia Nervosa",
    "Obesity",
    "Sleep Apnea",
    "Insomnia",
    "Restless Legs Syndrome",
    "Anemia",
    "Leukemia",
    "Lymphoma",
    "Thyroid Cancer",
    "Breast Cancer",
    "Prostate Cancer",
    "Lung Cancer",
    "Colorectal Cancer",
    "Bladder Cancer",
    "Kidney Stones",
    "Urinary Tract Infection (UTI)",
    "Prostatitis",
    "Endometriosis",
    "Polycystic Ovary Syndrome (PCOS)",
    "Menstrual Irregularities",
    "Pregnancy",
    "Postpartum Depression",
    "Menopause",
    "Testicular Torsion",
    "Erectile Dysfunction",
    "Infertility",
    "Dyspepsia",
    "Gallstones",
    "Hernia",
    "Appendicitis",
    "Diverticulitis",
    "Pancreatitis",
    "Cholecystitis"
]

remarks = [
    "Need more rest",
    "To monitor after giving medicine",
    "Follow up in 2 weeks",
    "Prescribe inhaler for better management",
    "Increase fluid intake",
    "Dietary changes recommended",
    "Refer to specialist for further evaluation",
    "Monitor blood pressure regularly",
    "Regular glucose level checks required",
    "Review thyroid function tests",
    "Counsel on lifestyle changes",
    "Start physical therapy",
    "Follow-up for imaging",
    "Recommend sleep study",
    "Increase physical activity",
    "Follow up with cardiology",
    "Advise on stress management techniques",
    "Ensure medication adherence",
    "Educate on trigger avoidance",
    "Perform routine blood work",
    "Monitor weight and diet",
    "Schedule a follow-up visit",
    "Evaluate need for additional medications",
    "Refer to nutritionist",
    "Check for possible side effects",
    "Encourage daily exercise",
    "Assess effectiveness of current treatment",
    "Provide support resources",
    "Review pain management options",
    "Monitor for signs of infection",
    "Recommend allergy testing",
    "Review vaccination status",
    "Counsel on mental health support",
    "Adjust dosage as needed",
    "Reassess symptoms in 6 weeks",
    "Encourage hydration",
    "Monitor blood sugar levels",
    "Advise on skin care routine",
    "Check for improvement in symptoms",
    "Monitor liver function tests",
    "Suggest relaxation techniques",
    "Refer to physical therapist",
    "Update medication list",
    "Monitor for signs of relapse",
    "Provide information on disease management",
    "Ensure patient understands treatment plan",
    "Review family medical history",
    "Provide dietary recommendations",
    "Follow up on test results",
    "Assess for possible drug interactions",
    "Encourage regular check-ups",
    "Monitor cholesterol levels",
    "Review patient’s symptom diary",
    "Discuss long-term management strategies",
    "Evaluate need for additional testing",
    "Advise on proper medication storage",
    "Encourage participation in support groups",
    "Review and update emergency plan",
    "Educate on prevention strategies",
    "Monitor response to new medication",
    "Assess need for referral to specialist",
    "Review patient’s lifestyle choices",
    "Recommend stress reduction techniques",
    "Check for possible complications",
    "Provide guidance on self-care",
    "Monitor for adverse reactions",
    "Advise on proper nutrition",
    "Review patient’s adherence to treatment",
    "Encourage regular exercise routine",
    "Schedule follow-up appointments",
    "Provide information on available resources",
    "Monitor kidney function tests",
    "Assess patient’s progress",
    "Re-evaluate treatment plan",
    "Advise on sleep hygiene practices",
    "Encourage open communication with healthcare provider",
    "Review symptom management techniques",
    "Monitor for signs of dehydration",
    "Recommend relaxation exercises",
    "Advise on proper wound care",
    "Check for improvement with current therapy",
    "Discuss impact on daily activities",
    "Review patient’s medication schedule",
    "Provide education on disease prevention",
    "Monitor for changes in symptoms",
    "Advise on regular health screenings",
    "Check for improvement in pain levels",
    "Provide resources for additional support",
    "Encourage patient engagement in treatment plan",
    "Review and adjust medication as needed",
    "Discuss potential lifestyle modifications",
    "Monitor for side effects of new medications",
    "Encourage regular follow-ups",
    "Assess need for additional interventions",
    "Provide support for chronic disease management",
    "Review patient’s health goals",
    "Monitor overall well-being",
    "Assess impact on quality of life",
    "Advise on maintaining a healthy lifestyle",
    "Encourage adherence to medical advice",
    "Review patient’s coping strategies",
    "Provide information on upcoming tests",
    "Monitor effectiveness of current interventions",
    "Assess need for referral to additional specialists"
]

treatments = [
{
    "id"        : 1,
    "treatment" : "acupuncture", 
    "frequency" : 10
},
{   
    "id"        : 2,
    "treatment" :"cupping", 
    "frequency" : 10
    },
{
    "id"        : 3,
    "treatment" : "bone setting", 
    "frequency" : 8
},
{
    "id"        : 4,
    "treatment" : "beauty",
    "frequency" : 5
},
{
    "id"        : 5,
    "treatment" : "massage",
    "frequency" : 7
},
{
    "id"        : 6,
    "treatment" : "guasha",
    "frequency" : 3
},
]


def create_empty_dictionary():
    # initialize the dictionary
    patient_datas = {}
    package_ids = list(range(1, 7))

    for patient_id in patient_ids:
        patient_datas[patient_id] = {}

    for package_id in package_ids:
        for _, v in patient_datas.items():
            v[package_id] = {}
    return patient_datas

def get_random_package():
    return random.randint(1,6)
    
def get_package_details(patient_id, patient_package_dict, appointment_shortdate):
       
    package_id = get_random_package()
    # print(package_id)
    selected_treatment_dict = treatments[package_id-1]
    
    limit = selected_treatment_dict["frequency"]
    temp_dict = patient_package_dict[patient_id][package_id]
    
    # check visit_count
    if not "visit_count" in temp_dict:
        temp_dict["visit_count"] = 1
        package_payment_date = appointment_shortdate
        
    elif temp_dict["visit_count"] == limit:
        # reset old packages
        temp_dict["visit_count"] = 1
        package_payment_date = appointment_shortdate
              
    elif temp_dict["visit_count"] < limit:
        temp_dict["visit_count"] += 1
        package_payment_date = None
        
    else:
        pass
    
    return package_id, package_payment_date, patient_package_dict

def get_selected_patient(selected_patients):
    # if selected patient id has not been selected for the day, select that id and keep track of the id in a list
    while True:
        selected_patient = random.choice(patient_ids)
            
        if not selected_patient in selected_patients:
            selected_patients.append(selected_patient)
            break
    
    return selected_patient


def get_next_appointment_date(appointment_date):
    boolean = [True, False]
    if random.choice(boolean) == True:
        next_appointment_date = appointment_date + timedelta(days=random.randint(1,15))
    else:
        next_appointment_date = None
        
    return next_appointment_date

def get_appointment_date(new_date):
    # mysql format: YYYY-MM-DD hh:mm:ss
    # assume clinic open from 8am to 8pm 08:00:00 to 20:00:00
    min_hour = 8
    max_hour = 20
    min_minute = 0
    max_minute = 59
    min_second = 0
    max_second = 59

    hours = random.randint(min_hour, max_hour)
    minutes = random.randint(min_minute, max_minute)
    seconds = random.randint(min_second, max_second)

    new_date_obj = new_date.timetuple()
    year = new_date_obj[0]
    month = new_date_obj[1]
    day = new_date_obj[2]

    appointment_date = datetime.datetime(year, month, day, hours, minutes, seconds)
    appointment_shortdate = datetime.date(year, month, day)
    
    return appointment_date, appointment_shortdate
    
def write_to_csv(call_statements):
    with open("testfile.csv", "w", newline="\n") as f:
        write = csv.writer(f)
        rows = [[statement] for statement in call_statements]
        write.writerows(rows)

def write_to_csv_test(patient_datas):
    print(patient_datas)
    df = pd.DataFrame(patient_datas)
    
    df.to_csv("samplefile.csv", index=False)
    
def main():

    call_statements = []

    # start_date = datetime.date(2024, 8, 1)
    day_increment = 0
    # total_days = 60

    patient_datas = []

    patient_package_dict = create_empty_dictionary()
    
    while day_increment <= total_days:
        
        new_date = start_date + timedelta(days=day_increment)
        
        # define how many appointments per day
        appointment_count = random.randint(5, 15)
        
        # initialize an empty list to hold patients of the day
        selected_patients = []
        for i in range(appointment_count):
            
            selected_patient = get_selected_patient(selected_patients)
            
            selected_doctor = random.choice(doctor_ids)
            cost = random.randint(50, 150)
            diagnosis = random.choice(diagnoses)
            remark = random.choice(remarks)
            
            appointment_date, appointment_shortdate = get_appointment_date(new_date)
            next_appointment_date = get_next_appointment_date(appointment_date)
            
            if day_increment % 2 == 0:
                package_id = None
                package_payment_date = None
            else:
                package_id, package_payment_date, patient_package_dict = get_package_details(selected_patient, patient_package_dict, appointment_shortdate)
                          
            # Process the variables to ensure correct SQL syntax
            package_id_str = f"\"{package_id}\"" if package_id is not None else 'NULL'
            package_payment_date_str = f"\"{package_payment_date}\"" if package_payment_date is not None else 'NULL'
            appointment_date_str = f"\"{appointment_date}\"" if appointment_date is not None else 'NULL'
            next_appointment_date_str = f"\"{next_appointment_date}\"" if next_appointment_date is not None else 'NULL'

            # Now build the f-string
            call_statement = (
                f"CALL insert_appointment("
                f"\"{selected_patient}\", "
                f"\"{selected_doctor}\", "
                f"{appointment_date_str}, "
                f"{next_appointment_date_str}, "
                f"\"{cost}\", "
                f"\"{diagnosis}\", "
                f"\"{remark}\", "
                f"{package_id_str}, "
                f"{package_payment_date_str}"
                f");"
            )          
            
            patient_data = {
                "patient_id"            : selected_patient,
                "appointment_date"      : appointment_date,
                "package_id"            : package_id,
                "package_payment_date"  : package_payment_date
            }
            
            patient_datas.append(patient_data)
            call_statements.append(call_statement)

        # proceed to next day
        day_increment += 1 

    write_to_csv(call_statements)
    write_to_csv_test(patient_datas)
    
if __name__ == "__main__":
    main()