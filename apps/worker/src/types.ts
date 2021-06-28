interface BaseFields {
  id: string;
  updated_at: string;
  created_at: string;
}

interface UserEmail extends BaseFields {
  user_id: string;
  email: string;
  is_verified: string;
  is_primary: string;
}
