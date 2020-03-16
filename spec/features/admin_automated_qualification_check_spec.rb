require "rails_helper"

RSpec.feature "Admins automated qualification check" do
  let(:user) { create(:dfe_signin_user) }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
  end

  scenario "Service operators can upload and run automated DQT checks" do
    maths_and_physics_claim = create(:claim, :submitted, policy: MathsAndPhysics, date_of_birth: Date.new(1990, 8, 23))
    student_loans_claim = create(:claim, :submitted, policy: StudentLoans, date_of_birth: Date.new(1990, 8, 23))
    claim_with_ineligible_record = create(:claim, :submitted, policy: StudentLoans, date_of_birth: Date.new(1990, 8, 23))
    claim_with_decision = create(:claim, :approved, date_of_birth: Date.new(1990, 8, 23))
    existing_qualification_task = create(:task, name: "qualifications", passed: false, created_at: 10.minutes.ago)
    claim_with_qualification_task = create(:claim, :submitted, tasks: [existing_qualification_task], date_of_birth: Date.new(1990, 8, 23))

    click_on "View claims"
    click_on "Upload DQT report"

    csv = <<~CSV
      dfeta text1,dfeta text2,dfeta trn,fullname,birthdate,dfeta ninumber,dfeta qtsdate,dfeta he hesubject1idname,dfeta he hesubject2idname,dfeta he hesubject3idname,HESubject1Value,HESubject2Value,HESubject3Value,dfeta subject1idname,dfeta subject2idname,dfeta subject3idname,ITTSub1Value,ITTSub2Value,ITTSub3Value
      1234567,#{maths_and_physics_claim.reference},1234567,Fred Smith,23/8/1990,QQ123456C,23/8/2017,Politics,,,L200,,,Mathematics,,,G100,,
      7654321,#{student_loans_claim.reference},7654321,Fred Smith,23/8/1990,QQ123456C,2/3/2016,Politics,,,L200,,,Politics,,,L200,,
      3456789,Not valid,3456789,,,,,,,,,,,,,,,,
      6758493,#{claim_with_ineligible_record.reference},6758493,Fred Smith,23/8/1990,QQ123456C,2/3/1980,Politics,,,L200,,,Politics,,,L200,,
      5554433,#{claim_with_decision.reference},5554433,Fred Smith,23/8/1990,QQ123456C,2/3/1980,Politics,,,L200,,,Politics,,,L200,,
      6060606,#{claim_with_qualification_task.reference},6060606,Fred Smith,23/8/1990,QQ123456C,2/3/1980,Politics,,,L200,,,Politics,,,L200,,
    CSV

    file = Tempfile.new
    file.write(csv)
    file.rewind

    attach_file("Upload a CSV file", file.path)

    click_on "Upload"

    expect(page).to have_content "DQT data uploaded successfully"
    expect(maths_and_physics_claim.tasks.find_by!(name: "qualifications").passed?).to eq(true)
    expect(student_loans_claim.tasks.find_by!(name: "qualifications").passed?).to eq(true)
    expect(claim_with_ineligible_record.tasks.find_by(name: "qualifications")).to be_nil
    expect(claim_with_decision.tasks.find_by(name: "qualifications")).to be_nil
    expect(claim_with_qualification_task.tasks.find_by(name: "qualifications")).to eq(existing_qualification_task)
  end
end
