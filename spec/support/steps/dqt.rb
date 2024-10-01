def when_dqt_stubbed
  dqt_teacher_resource = instance_double(Dqt::TeacherResource, find: nil)
  dqt_client = instance_double(Dqt::Client, teacher: dqt_teacher_resource)
  allow(Dqt::Client).to receive(:new).and_return(dqt_client)
end
