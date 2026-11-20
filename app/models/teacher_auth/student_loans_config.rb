module TeacherAuth
  class StudentLoansConfig < Config
    def path_prefix
      "/student-loans/auth"
    end

    def request_path
      "#{path_prefix}/teacher_student_loans"
    end

    def callback_path
      "#{request_path}/callback"
    end

    def identifier
      ENV["TEACHER_AUTH_STUDENT_LOANS_CLIENT_ID"]
    end

    def secret
      ENV["TEACHER_AUTH_STUDENT_LOANS_SECRET"]
    end
  end
end
