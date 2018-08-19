{ fetchCoursier }:

{
  bouncycastle =
    fetchCoursier {
      organisation = "org.bouncycastle";
      module = "bcprov-jdk15on";
      revision = "1.59";
      sha256 = "1rr7byqmaxyd8jlnpb618fg9s7ww15yirkcq93zvlk94mywmkgb6";
    };
}
